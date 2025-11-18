/***************************************************
  MAX30102 心率血氧感測器程式
  
  腳位連接：
  - VCC => VDD1
  - GND => GND
  - SDA => SDA1 (D20)
  - SCL => SCL1 (D21)
  
  功能：
  - 讀取心率 (Heart Rate)
  - 讀取血氧 (SpO2)
  - Serial 輸出數據
 ****************************************************/

#include <Wire.h>
#include "MAX30102.h"

MAX30105 particleSensor;

// 心率計算相關變數
const byte RATE_SIZE = 4; // 用於平均的樣本數
byte rates[RATE_SIZE];    // 心率陣列
byte rateSpot = 0;
long lastBeat = 0;        // 上次心跳時間
float beatsPerMinute;
int beatAvg;

// 血氧計算相關變數
uint32_t irBuffer[100];   // 紅外線數據緩衝區
uint32_t redBuffer[100];  // 紅光數據緩衝區
int32_t bufferLength;     // 數據長度
int32_t spo2;             // 血氧值
int8_t validSPO2;         // 血氧值是否有效
int32_t heartRate;        // 心率值
int8_t validHeartRate;    // 心率值是否有效

// 感測器狀態
bool sensorReady = false;

void setup()
{
  Serial.begin(115200);
  Serial.println("MAX30102 心率血氧感測器初始化中...");

  // 初始化 I2C1 (SDA1=D20, SCL1=D21)
  Wire1.begin();
  
  // 初始化感測器
  if (!particleSensor.begin(Wire1, I2C_SPEED_FAST)) {
    Serial.println("錯誤：無法找到 MAX30102 感測器！");
    Serial.println("請檢查連接：");
    Serial.println("  - SDA 連接到 SDA1 (D20)");
    Serial.println("  - SCL 連接到 SCL1 (D21)");
    Serial.println("  - VCC 連接到 VDD1");
    Serial.println("  - GND 連接到 GND");
    while (1); // 停止執行
  }

  Serial.println("MAX30102 感測器已找到！");

  // 配置感測器參數
  byte ledBrightness = 60;  // 亮度 (0-255)
  byte sampleAverage = 4;   // 樣本平均數
  byte ledMode = 2;         // 模式：2 = Red + IR
  int sampleRate = 100;     // 採樣率：100, 200, 400, 800, 1000, 1600, 3200
  int pulseWidth = 411;     // 脈衝寬度：69, 118, 215, 411
  int adcRange = 4096;      // ADC 範圍：2048, 4096, 8192, 16384

  particleSensor.setup(ledBrightness, sampleAverage, ledMode, sampleRate, pulseWidth, adcRange);
  
  // 初始化心率陣列
  for (byte x = 0 ; x < RATE_SIZE ; x++) {
    rates[x] = 0;
  }

  sensorReady = true;
  Serial.println("感測器配置完成！");
  Serial.println("請將手指放在感測器上...");
  Serial.println("==========================================");
  delay(2000);
}

void loop()
{
  if (!sensorReady) {
    return;
  }

  long irValue = particleSensor.getIR();
  long redValue = particleSensor.getRed();

  // 計算血氧值（使用演算法，同時計算心率）
  calculateSPO2(irValue, redValue);
  
  // 檢查是否有手指放在感測器上
  if (irValue > 50000) {
    // 方法1：使用 checkForBeat 檢測心跳
    if (checkForBeat(irValue) == true) {
      // 檢測到心跳
      long delta = millis() - lastBeat;
      if (delta > 0) {
        lastBeat = millis();
        beatsPerMinute = 60000.0 / delta;

        if (beatsPerMinute < 255 && beatsPerMinute > 20) {
          rates[rateSpot++] = (byte)beatsPerMinute;
          rateSpot %= RATE_SIZE; // 循環使用陣列

          // 計算平均心率
          beatAvg = 0;
          int validRates = 0;
          for (byte x = 0 ; x < RATE_SIZE ; x++) {
            if (rates[x] > 0) {
              beatAvg += rates[x];
              validRates++;
            }
          }
          if (validRates > 0) {
            beatAvg /= validRates;
          }
        }
      }
    }
    
    // 方法2：如果 checkForBeat 沒有結果，使用血氧演算法計算的心率
    if (beatAvg == 0 && validHeartRate == 1 && heartRate > 0) {
      beatAvg = heartRate;
    }
  } else {
    // 重置心率相關變數
    beatAvg = 0;
    lastBeat = 0;
  }

  // 輸出即時數據
  Serial.print("IR=");
  Serial.print(irValue);
  Serial.print(", Red=");
  Serial.print(redValue);
  
  if (irValue < 50000) {
    Serial.println(" - 未偵測到手指");
    beatAvg = 0;
    spo2 = 0;
  } else {
    Serial.print(", 心率=");
    if (beatAvg > 0) {
      Serial.print(beatAvg);
      Serial.print(" BPM");
    } else {
      Serial.print("計算中...");
    }
    
    if (spo2 > 0 && validSPO2 == 1) {
      Serial.print(", 血氧=");
      Serial.print(spo2);
      Serial.print("%");
    } else {
      Serial.print(", 血氧=計算中...");
    }
    Serial.println();
  }

  delay(100); // 延遲 100ms
}

// 簡化的血氧計算函數
void calculateSPO2(long irValue, long redValue) {
  static int sampleCount = 0;
  static bool bufferFull = false;
  
  // 將數據存入緩衝區
  if (sampleCount < 100) {
    irBuffer[sampleCount] = irValue;
    redBuffer[sampleCount] = redValue;
    sampleCount++;
  } else {
    bufferFull = true;
    // 移動數據，保持最新的 100 個樣本
    for (int i = 0; i < 99; i++) {
      irBuffer[i] = irBuffer[i + 1];
      redBuffer[i] = redBuffer[i + 1];
    }
    irBuffer[99] = irValue;
    redBuffer[99] = redValue;
  }

  // 當緩衝區滿了後，計算血氧
  if (bufferFull && sampleCount >= 100) {
    bufferLength = 100;
    
    // 調用血氧演算法
    maxim_heart_rate_and_oxygen_saturation(
      irBuffer, bufferLength, redBuffer,
      &spo2, &validSPO2, &heartRate, &validHeartRate
    );
  }
}
