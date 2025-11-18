/***************************************************
  DHT-11 溫濕度感測器程式
  
  腳位連接：
  - VCC => VDD3 (5V)
  - GND => GND
  - DATA => D7
  
  功能：
  - 讀取溫度 (Temperature)
  - 讀取濕度 (Humidity)
  - Serial 輸出數據
 ****************************************************/

#include "DHT11.h"

#define DHT11_PIN 7

DHT11 dht(DHT11_PIN);

// 感測器狀態
bool sensorReady = false;

void setup()
{
  Serial.begin(115200);
  Serial.println("DHT-11 溫濕度感測器初始化中...");

  // 初始化感測器
  if (!dht.begin()) {
    Serial.println("錯誤：無法初始化 DHT-11 感測器！");
    Serial.println("請檢查連接：");
    Serial.println("  - DATA 連接到 D7");
    Serial.println("  - VCC 連接到 VDD3 (5V)");
    Serial.println("  - GND 連接到 GND");
    while (1); // 停止執行
  }

  sensorReady = true;
  Serial.println("DHT-11 感測器初始化完成！");
  Serial.println("開始讀取溫濕度數據...");
  Serial.println("==========================================");
  delay(2000); // 等待感測器穩定
}

void loop()
{
  if (!sensorReady) {
    return;
  }

  float humidity = 0;
  float temperature = 0;

  // 讀取溫濕度
  if (dht.read(&humidity, &temperature)) {
    // 輸出數據
    Serial.print("濕度: ");
    Serial.print(humidity, 1);
    Serial.print("%");
    
    Serial.print("  |  溫度: ");
    Serial.print(temperature, 1);
    Serial.println("°C");
  } else {
    Serial.println("讀取失敗，請檢查感測器連接");
  }

  delay(2000); // DHT-11 需要至少 2 秒的讀取間隔
}

