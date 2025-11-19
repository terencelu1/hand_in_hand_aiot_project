#include "BMH12M105.h"          // 秤重模組
#include "BMK52T016.h"          // 按鍵模組
#include "BMD31M090.h"          // OLED 顯示模組
#include "Bitmap.h"             // 位圖顯示相關
#include "ThingSpeakPublish.h"  // ThingSpeak 上傳模組
#include <Wire.h>               // I2C 通訊
#include "Timer.h"              // 計時器模組

// 定義 OLED 顯示模組的參數
#define BMD31M090_WIDTH   128        // OLED 顯示寬度，單位：像素
#define BMD31M090_HEIGHT  64         // OLED 顯示高度，單位：像素
#define BMD31M090_ADDRESS 0x3C       // OLED I2C 通訊地址

// 初始化模組
BMH12M105 weight(&Wire1, 0x50);      // 秤重模組初始化
BMK52T016 BMK52(2, &Wire1);          // 按鍵模組初始化
BMD31M090 BMD31(BMD31M090_WIDTH, BMD31M090_HEIGHT, &Wire1); // OLED 模組初始化
BMC81M001 Wifi(&Serial3);            // WiFi 模組初始化

// 全域變數
int16_t readData = 0;    // 讀取到的重量數據
int16_t previousData = 0; // 上一次讀取的重量數據
unsigned int keyValue = 0; // 按鍵值
Timer t;                  // Timer 物件，用於定期執行任務

void setup() {
  Serial.begin(115200);    // 設置串口通信速率
  Wire1.begin();           // 初始化 I2C 通訊
  BMK52.begin();           // 啟動按鍵模組
  weight.begin();          // 啟動秤重模組
  
  BMD31.begin(BMD31M090_ADDRESS); // 啟動 OLED 顯示模組
  delay(100);                    // 初始化延遲

  // 初始化 WiFi 連接
  Wifi.begin();
  Wifi.reset();
  Serial.print("WiFi Connection Results：");
  if (Wifi.connectToAP(WIFI_SSID, WIFI_PASS) == 0) {
    Serial.println("fail");
  } else {
    Serial.println("success");
  }

  // 初始化 ThingSpeak 連接
  Serial.print("ThingSpeak Connection Results：");
  if (Wifi.configMqtt(CLIENTLID, USERNAME, PASSWORD, MQTT_HOST, SERVER_PORT) == 0) {
    Serial.println("fail");
  } else {
    Serial.println("success");
  }

  delay(200);  // 延遲確保連接穩定
  Wifi.setPublishTopic(PUBLISHTOPIC); // 設置上傳主題
  Wifi.setSubscribetopic(SUBSCRIBERTOPIC1); // 設置訂閱主題1
  Wifi.setSubscribetopic(SUBSCRIBERTOPIC2); // 設置訂閱主題2

  // 使用 Timer 定期檢查按鍵和重量傳感器，每100毫秒執行一次
  t.every(100, checkSensors);   
  // 使用 Timer 每10秒上傳一次數據
  t.every(10000, sendData);      
}

void loop() {
  t.update(); // 更新 Timer，執行定時任務
}

// 檢查按鍵與秤重感測器
void checkSensors() {
  // 檢查按鍵中斷
  if (BMK52.getINT() == 0) {
    keyValue = BMK52.readKeyValue(); // 讀取按鍵值
    Serial.print("keyValue (Binary): ");
    Serial.println(keyValue, BIN);

    // 如果按鍵1被按下，執行秤重模組歸零操作
    if (keyValue == 0b1) {
      uint8_t result = weight.calibrationZero(); // 歸零校正
      if (result == 0) {
        Serial.println("Calibrating Zero: Success");
      } else {
        Serial.println("Calibrating Zero: Failed");
      }
    }
  }

  // 讀取重量數據
  readData = weight.readWeight();
  // 如果重量數據發生變化，更新顯示
  if (previousData != readData) {
    previousData = readData;
    updateDisplay();
  }
}

// 更新 OLED 顯示
void updateDisplay() {
  BMD31.clearDisplay(); // 清除顯示內容以便完整刷新
  BMD31.display();
  BMD31.setFont(FontTable_8X16); // 設置字體
  BMD31.drawString(0, displayROW2, (u8*)"Weight: "); // 顯示"Weight:"字樣
  char buffer[10];
  snprintf(buffer, sizeof(buffer), "%d", previousData); // 將重量數據轉換為字串
  BMD31.drawString(72, displayROW2, (u8*)buffer); // 在顯示器上顯示重量數值
  
  Serial.print("Updated OLED Display: ");
  Serial.println(buffer);
}

// 上傳數據到 ThingSpeak
void sendData() {
  String Weight = String(previousData); // 將重量數據轉換為字串
  String DATA_BUF = "field1=" + Weight; // 構建上傳數據字串
  if (Wifi.writeString(DATA_BUF, PUBLISHTOPIC)) { // 發送數據
    Serial.println("Send String data success");
  } else {
    Serial.println("Send String data failed");
  }
}
