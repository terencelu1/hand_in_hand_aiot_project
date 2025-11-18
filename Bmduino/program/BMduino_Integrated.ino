/***************************************************
  BMduino 整合程式 - 三模式系統
  
  模式說明：
  1. 待機模式：持續感測 GY906、指紋辨識、心律血氧，回報狀態
  2. 工作模式：指紋觸發後，測量心律血氧，數據穩定後回報
  3. 接收模式：接收樹莓派命令，控制繼電器
  
  腳位連接：
  - AS608 指紋辨識：TX=>D2, RX=>D3
  - 4 Relay：IN1=>D8, IN2=>D9, IN3=>D10, IN4=>D11
  - MAX30102：SDA=>SDA1(D20), SCL=>SCL1(D21)
  - GY-906：SDA=>SDA(D18), SCL=>SCL(D19)
  
  通訊：Native USB (SerialUSB)
  ****************************************************/

#include <SoftwareSerial.h>
#include <Adafruit_Fingerprint.h>
#include <Wire.h>
#include "MAX30102.h"
#include "../code/GY-906/GY906.h"

// ========== 腳位定義 ==========
// 指紋辨識
SoftwareSerial mySerial(2, 3);  // RX, TX
Adafruit_Fingerprint finger = Adafruit_Fingerprint(&mySerial);

// 繼電器
const int relay1 = 8;   // IN1
const int relay2 = 9;   // IN2
const int relay3 = 10;  // IN3
const int relay4 = 11;  // IN4

// 感測器物件
MAX30105 particleSensor;
MLX90614 mlx;

// ========== 模式定義 ==========
enum SystemMode {
  MODE_STANDBY,    // 待機模式
  MODE_WORKING,    // 工作模式
  MODE_RECEIVE     // 接收模式
};

SystemMode currentMode = MODE_STANDBY;

// ========== 感測器狀態 ==========
bool gy906Ready = false;
bool max30102Ready = false;
bool fingerprintReady = false;

// ========== MAX30102 變數 ==========
const byte RATE_SIZE = 4;
byte rates[RATE_SIZE];
byte rateSpot = 0;
long lastBeat = 0;
float beatsPerMinute;
int beatAvg;
uint32_t irBuffer[100];
uint32_t redBuffer[100];
int32_t bufferLength;
int32_t spo2;
int8_t validSPO2;
int32_t heartRate;
int8_t validHeartRate;

// ========== 工作模式變數 ==========
unsigned long workModeStartTime = 0;
const unsigned long WORK_MODE_TIMEOUT = 45000; // 45秒超時（給足夠時間測量）
const unsigned long DATA_STABLE_TIME = 3000;   // 數據穩定時間 3秒
const unsigned long FINGER_PLACEMENT_TIME = 3000; // 給用戶時間放置手指 3秒
const unsigned long STATUS_REPORT_INTERVAL = 1000; // 狀態回報間隔 1秒
unsigned long lastValidDataTime = 0;
unsigned long lastStatusReport = 0;
bool dataStable = false;
bool heartRateReady = false;  // 心率是否已準備好
bool spo2Ready = false;       // 血氧是否已準備好
int noFingerCount = 0;  // 連續沒有手指的次數
const int MAX_NO_FINGER_COUNT = 60;  // 連續60次沒有手指才退出（約3秒，每次循環50ms）

// ========== 待機模式變數 ==========
unsigned long lastStandbyReport = 0;
const unsigned long STANDBY_REPORT_INTERVAL = 1000; // 1秒回報一次

// ========== 初始化 ==========
void setup() {
  // 初始化 Native USB
  SerialUSB.begin(115200);
  delay(1000);
  
  SerialUSB.println("========================================");
  SerialUSB.println("BMduino 整合系統啟動");
  SerialUSB.println("========================================");
  
  // 初始化繼電器
  initRelays();
  
  // 初始化 I2C
  Wire.begin();      // 標準 I2C (GY-906)
  Wire1.begin();     // I2C1 (MAX30102)
  
  // 初始化感測器
  initGY906();
  initMAX30102();
  initFingerprint();
  
  SerialUSB.println("系統初始化完成");
  SerialUSB.println("進入待機模式");
  SerialUSB.println("========================================");
  
  currentMode = MODE_STANDBY;
}

// ========== 主迴圈 ==========
void loop() {
  switch (currentMode) {
    case MODE_STANDBY:
      handleStandbyMode();
      break;
    case MODE_WORKING:
      handleWorkingMode();
      break;
    case MODE_RECEIVE:
      handleReceiveMode();
      break;
  }
  
  // 檢查指紋辨識（待機模式和工作模式需要檢查）
  if (currentMode != MODE_RECEIVE) {
    checkFingerprint();
  }
  
  // 檢查是否進入接收模式（從待機模式切換）
  // 在待機模式下，如果有命令輸入，自動切換到接收模式
  if (currentMode == MODE_STANDBY && SerialUSB.available() > 0) {
    currentMode = MODE_RECEIVE;
    SerialUSB.println("MODE,RECEIVE");
  }
  
  delay(50);
}

// ========== 待機模式 ==========
void handleStandbyMode() {
  unsigned long currentTime = millis();
  
  // 定期回報狀態
  if (currentTime - lastStandbyReport >= STANDBY_REPORT_INTERVAL) {
    lastStandbyReport = currentTime;
    
    // 讀取 GY906 溫度
    float objectTemp = 0, ambientTemp = 0;
    if (gy906Ready) {
      objectTemp = mlx.readObjectTemp();
      ambientTemp = mlx.readAmbientTemp();
    }
    
    // 讀取 MAX30102（待機模式只讀取，不要求穩定）
    int currentHeartRate = 0;
    int currentSPO2 = 0;
    if (max30102Ready) {
      long irValue = particleSensor.getIR();
      long redValue = particleSensor.getRed();
      calculateSPO2(irValue, redValue);
      
      if (irValue > 50000) {
        if (checkForBeat(irValue)) {
          long delta = millis() - lastBeat;
          if (delta > 0) {
            lastBeat = millis();
            beatsPerMinute = 60000.0 / delta;
            if (beatsPerMinute < 255 && beatsPerMinute > 20) {
              rates[rateSpot++] = (byte)beatsPerMinute;
              rateSpot %= RATE_SIZE;
              beatAvg = 0;
              int validRates = 0;
              for (byte x = 0; x < RATE_SIZE; x++) {
                if (rates[x] > 0) {
                  beatAvg += rates[x];
                  validRates++;
                }
              }
              if (validRates > 0) beatAvg /= validRates;
            }
          }
        }
        if (beatAvg == 0 && validHeartRate == 1 && heartRate > 0) {
          beatAvg = heartRate;
        }
        currentHeartRate = beatAvg;
        if (spo2 > 0 && validSPO2 == 1) {
          currentSPO2 = spo2;
        }
      }
    }
    
    // 回報狀態：模式,物體溫度,環境溫度,心率,血氧
    SerialUSB.print("STANDBY,");
    SerialUSB.print(objectTemp, 2);
    SerialUSB.print(",");
    SerialUSB.print(ambientTemp, 2);
    SerialUSB.print(",");
    SerialUSB.print(currentHeartRate);
    SerialUSB.print(",");
    SerialUSB.println(currentSPO2);
  }
}

// ========== 工作模式 ==========
void handleWorkingMode() {
  unsigned long currentTime = millis();
  unsigned long timeSinceStart = currentTime - workModeStartTime;
  
  // 檢查超時
  if (timeSinceStart > WORK_MODE_TIMEOUT) {
    SerialUSB.println("WORKING,TIMEOUT");
    currentMode = MODE_STANDBY;
    noFingerCount = 0;
    dataStable = false;
    heartRateReady = false;
    spo2Ready = false;
    return;
  }
  
  // 讀取 GY906
  float objectTemp = 0, ambientTemp = 0;
  if (gy906Ready) {
    objectTemp = mlx.readObjectTemp();
    ambientTemp = mlx.readAmbientTemp();
  }
  
  // 讀取 MAX30102
  int currentHeartRate = 0;
  int currentSPO2 = 0;
  bool hasFinger = false;
  
  if (max30102Ready) {
    long irValue = particleSensor.getIR();
    long redValue = particleSensor.getRed();
    calculateSPO2(irValue, redValue);
    
    // 檢查是否有手指（給用戶時間放置手指）
    if (irValue > 50000) {
      hasFinger = true;
      noFingerCount = 0;  // 重置計數器
      
      // 檢測心率
      if (checkForBeat(irValue)) {
        long delta = millis() - lastBeat;
        if (delta > 0) {
          lastBeat = millis();
          beatsPerMinute = 60000.0 / delta;
          // 心率範圍：30-140 BPM
          if (beatsPerMinute >= 30 && beatsPerMinute <= 140) {
            rates[rateSpot++] = (byte)beatsPerMinute;
            rateSpot %= RATE_SIZE;
            beatAvg = 0;
            int validRates = 0;
            for (byte x = 0; x < RATE_SIZE; x++) {
              if (rates[x] > 0) {
                beatAvg += rates[x];
                validRates++;
              }
            }
            if (validRates > 0) beatAvg /= validRates;
          }
        }
      }
      if (beatAvg == 0 && validHeartRate == 1 && heartRate > 0) {
        // 使用演算法計算的心率，也要檢查範圍
        if (heartRate >= 30 && heartRate <= 140) {
          beatAvg = heartRate;
        }
      }
      
      // 檢查心率是否有效（範圍：30-140 BPM）
      if (beatAvg >= 30 && beatAvg <= 140) {
        currentHeartRate = beatAvg;
        if (!heartRateReady) {
          heartRateReady = true;
        }
      } else {
        // 心率超出範圍，視為無效
        currentHeartRate = 0;
        heartRateReady = false;
      }
      
      // 檢查血氧是否有效
      if (spo2 > 0 && validSPO2 == 1) {
        currentSPO2 = spo2;
        if (!spo2Ready) {
          spo2Ready = true;
        }
      }
    } else {
      // 沒有手指
      hasFinger = false;
      
      // 只有在過了放置手指的時間後才開始計數
      if (timeSinceStart > FINGER_PLACEMENT_TIME) {
        noFingerCount++;
        
        // 連續多次沒有手指才退出（避免誤判）
        if (noFingerCount >= MAX_NO_FINGER_COUNT) {
          SerialUSB.println("WORKING,NO_FINGER");
          currentMode = MODE_STANDBY;
          noFingerCount = 0;
          dataStable = false;
          heartRateReady = false;
          spo2Ready = false;
          return;
        }
      }
    }
  }
  
  // 定期輸出狀態（每1秒）
  if (currentTime - lastStatusReport >= STATUS_REPORT_INTERVAL) {
    lastStatusReport = currentTime;
    
    SerialUSB.print("WORKING,");
    SerialUSB.print(objectTemp, 2);
    SerialUSB.print(",");
    SerialUSB.print(ambientTemp, 2);
    SerialUSB.print(",");
    
    // 輸出心率（如果有就輸出，沒有就輸出"感測中"）
    if (heartRateReady && currentHeartRate > 0) {
      SerialUSB.print(currentHeartRate);
    } else {
      SerialUSB.print("MEASURING");
    }
    SerialUSB.print(",");
    
    // 輸出血氧（如果有就輸出，沒有就輸出"感測中"）
    if (spo2Ready && currentSPO2 > 0) {
      SerialUSB.println(currentSPO2);
    } else {
      SerialUSB.println("MEASURING");
    }
  }
  
  // 檢查是否兩個數據都準備好了
  // 邏輯：如果血氧有數值，就等待心率也有數值
  if (spo2Ready && currentSPO2 > 0) {
    // 血氧已經有了，等待心率
    if (heartRateReady && currentHeartRate > 0) {
      // 兩個數據都有了，檢查穩定時間
      if (!dataStable) {
        // 開始穩定計時
        lastValidDataTime = currentTime;
        dataStable = true;
      } else {
        // 數據已穩定，檢查是否穩定足夠時間
        if (currentTime - lastValidDataTime >= DATA_STABLE_TIME) {
          // 輸出最終結果
          SerialUSB.print("WORKING,FINAL,");
          SerialUSB.print(objectTemp, 2);
          SerialUSB.print(",");
          SerialUSB.print(ambientTemp, 2);
          SerialUSB.print(",");
          SerialUSB.print(currentHeartRate);
          SerialUSB.print(",");
          SerialUSB.println(currentSPO2);
          
          // 完成後回到待機模式
          currentMode = MODE_STANDBY;
          dataStable = false;
          noFingerCount = 0;
          heartRateReady = false;
          spo2Ready = false;
        }
      }
    } else {
      // 血氧有了但心率還沒有，繼續等待（重置穩定計時）
      dataStable = false;
    }
  } else {
    // 血氧還沒有，繼續等待（重置穩定計時）
    dataStable = false;
  }
}

// ========== 接收模式 ==========
void handleReceiveMode() {
  if (SerialUSB.available() > 0) {
    String command = SerialUSB.readStringUntil('\n');
    command.trim();
    
    // 解析命令格式：RELAY,1 或 RELAY,2 等
    if (command.startsWith("RELAY,")) {
      int relayNum = command.substring(6).toInt();
      if (relayNum >= 1 && relayNum <= 4) {
        activateRelay(relayNum);
        SerialUSB.print("RELAY_OK,");
        SerialUSB.println(relayNum);
      } else {
        SerialUSB.println("RELAY_ERROR,INVALID_NUMBER");
      }
    } else {
      SerialUSB.println("RELAY_ERROR,INVALID_COMMAND");
    }
    
    // 執行完畢後回到待機模式
    currentMode = MODE_STANDBY;
  }
}

// ========== 檢查指紋辨識 ==========
void checkFingerprint() {
  if (!fingerprintReady) return;
  
  uint8_t p = finger.getImage();
  if (p != FINGERPRINT_OK) return;
  
  p = finger.image2Tz();
  if (p != FINGERPRINT_OK) return;
  
  p = finger.fingerSearch();
  if (p == FINGERPRINT_OK) {
    // 檢測到指紋，進入工作模式
    if (currentMode == MODE_STANDBY) {
      currentMode = MODE_WORKING;
      workModeStartTime = millis();
      dataStable = false;
      lastValidDataTime = 0;
      lastStatusReport = 0;
      noFingerCount = 0;  // 重置計數器
      heartRateReady = false;
      spo2Ready = false;
      SerialUSB.println("WORKING,START");
    }
  }
}

// ========== 初始化函數 ==========
void initRelays() {
  pinMode(relay1, OUTPUT);
  pinMode(relay2, OUTPUT);
  pinMode(relay3, OUTPUT);
  pinMode(relay4, OUTPUT);
  digitalWrite(relay1, HIGH);
  digitalWrite(relay2, HIGH);
  digitalWrite(relay3, HIGH);
  digitalWrite(relay4, HIGH);
}

void initGY906() {
  if (mlx.begin(Wire)) {
    gy906Ready = true;
    SerialUSB.println("GY-906 初始化成功");
  } else {
    SerialUSB.println("GY-906 初始化失敗");
  }
}

void initMAX30102() {
  if (particleSensor.begin(Wire1, I2C_SPEED_FAST)) {
    byte ledBrightness = 60;
    byte sampleAverage = 4;
    byte ledMode = 2;
    int sampleRate = 100;
    int pulseWidth = 411;
    int adcRange = 4096;
    particleSensor.setup(ledBrightness, sampleAverage, ledMode, sampleRate, pulseWidth, adcRange);
    
    for (byte x = 0; x < RATE_SIZE; x++) {
      rates[x] = 0;
    }
    
    max30102Ready = true;
    SerialUSB.println("MAX30102 初始化成功");
  } else {
    SerialUSB.println("MAX30102 初始化失敗");
  }
}

void initFingerprint() {
  mySerial.begin(57600);
  finger.begin(57600);
  delay(5);
  
  if (finger.verifyPassword()) {
    fingerprintReady = true;
    SerialUSB.println("指紋辨識器初始化成功");
  } else {
    SerialUSB.println("指紋辨識器初始化失敗");
  }
}

// ========== 繼電器控制 ==========
void activateRelay(int relayNum) {
  // 先關閉所有繼電器
  allRelaysOff();
  
  // 開啟指定繼電器
  int relayPin = 0;
  switch (relayNum) {
    case 1: relayPin = relay1; break;
    case 2: relayPin = relay2; break;
    case 3: relayPin = relay3; break;
    case 4: relayPin = relay4; break;
  }
  
  if (relayPin > 0) {
    digitalWrite(relayPin, LOW);  // 開啟
    delay(1000);                  // 保持1秒
    digitalWrite(relayPin, HIGH); // 關閉
  }
}

void allRelaysOff() {
  digitalWrite(relay1, HIGH);
  digitalWrite(relay2, HIGH);
  digitalWrite(relay3, HIGH);
  digitalWrite(relay4, HIGH);
}

// ========== MAX30102 計算函數（從 MAX30102.ino 複製） ==========
void calculateSPO2(long irValue, long redValue) {
  static int sampleCount = 0;
  static bool bufferFull = false;
  
  if (sampleCount < 100) {
    irBuffer[sampleCount] = irValue;
    redBuffer[sampleCount] = redValue;
    sampleCount++;
  } else {
    bufferFull = true;
    for (int i = 0; i < 99; i++) {
      irBuffer[i] = irBuffer[i + 1];
      redBuffer[i] = redBuffer[i + 1];
    }
    irBuffer[99] = irValue;
    redBuffer[99] = redValue;
  }

  if (bufferFull && sampleCount >= 100) {
    bufferLength = 100;
    maxim_heart_rate_and_oxygen_saturation(
      irBuffer, bufferLength, redBuffer,
      &spo2, &validSPO2, &heartRate, &validHeartRate
    );
  }
}

