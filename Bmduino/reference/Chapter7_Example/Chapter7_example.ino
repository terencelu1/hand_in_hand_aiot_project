#include "BMH12M105.h"          // 秤重模組
#include "BMD31M090.h"          // OLED 顯示模組
#include "BMS36T001.h"          // 馬達控制模組
#include "BMK52T016.h"          // 按鍵模組
#include "ThingSpeakPublish.h"  // ThingSpeak 上傳模組
#include <Wire.h>               // I2C 通訊
#include "Timer.h"              // 計時器模組

// 定義 OLED 顯示模組的參數
#define BMD31M090_WIDTH   128        // OLED 顯示寬度，單位：像素
#define BMD31M090_HEIGHT  64         // OLED 顯示高度，單位：像素
#define BMD31M090_ADDRESS 0x3C       // OLED I2C 通訊地址

// 初始化模組
BMH12M105 weight(&Wire1, 0x50);      // 秤重模組初始化
BMD31M090 BMD31(BMD31M090_WIDTH, BMD31M090_HEIGHT, &Wire1); // OLED 模組初始化
BMS36T001 BMS36(3, &Serial4); // 初始化馬達控制模組
BMK52T016 BMK52(2, &Wire1);          // 按鍵模組初始化
BMC81M001 Wifi(&Serial3);            // WiFi 模組初始化

// 全域變數
int16_t readData = 0;    // 讀取到的重量數據
int16_t previousData = -1; // 上一次讀取的重量數據
uint8_t irstatus = 0; // 用於存儲 IR 感測器的狀態
uint8_t lastIrStatus = 0; // 上一次的 IR 感測器狀態
Timer t;                  // Timer 物件，用於定期執行任務

void setup() {
  Serial.begin(115200);    // 設置串口通信速率
  Wire1.begin();           // 初始化 I2C 通訊
  weight.begin();          // 啟動秤重模組
  BMK52.begin();           // 啟動按鍵模組
  
  BMD31.begin(BMD31M090_ADDRESS); // 啟動 OLED 顯示模組
  delay(100);                    // 初始化延遲

  // 顯示 "Hello" 訊息
  BMD31.clearDisplay(); // 清除顯示內容以便完整刷新
  BMD31.display(); // 刷新顯示以確保顯示內容
  BMD31.setFont(FontTable_8X16); // 設置字體
  BMD31.drawString(0, 0, (u8*)"Ready"); // 在顯示器上顯示 "Ready"
  delay(2000);

  BMS36.begin(); // 初始化馬達模組

  // 初始化 WiFi 連接
  Wifi.begin();
  Wifi.reset();
  if (Wifi.connectToAP(WIFI_SSID, WIFI_PASS) == 0) {
    Serial.println("WiFi Connection Failed");
  } else {
    Serial.println("WiFi Connected");
  }

  // 初始化 ThingSpeak 連接
  if (Wifi.configMqtt(CLIENTLID, USERNAME, PASSWORD, MQTT_HOST, SERVER_PORT) == 0) {
    Serial.println("ThingSpeak Connection Failed");
  } else {
    Serial.println("ThingSpeak Connected");
  }
  Wifi.setPublishTopic(PUBLISHTOPIC); // 設置上傳主題
}

void loop() {
  // 檢查按鍵狀態
  checkKeypad();

  irstatus = BMS36.getIRStatus(); // 獲取 IR 感測器狀態
  
  // 只有當 IR 感測器狀態改變時才更新顯示
  if (irstatus != lastIrStatus) {
    if (irstatus == 1) { // 當 IR 感測器檢測到物體接近
      BMD31.clearDisplay(); // 清除顯示內容
      BMD31.display(); // 刷新顯示
      BMD31.setFont(FontTable_8X16); // 設置字體
      BMD31.drawString(0, 0, (u8*)"Closing"); // 顯示 "Closing"
      
      BMS36.motorForward(); // 馬達向前轉動
      delay(1000); // 馬達轉動 1 秒
      BMS36.motorStandby(); // 馬達待機
    } 
    lastIrStatus = irstatus; // 更新上一次的 IR 感測器狀態
  } else {
    checkWeightSensor(); // 檢查秤重感測器
  }
}

// 檢查按鍵狀態以觸發去皮功能
void checkKeypad() {
  String Weight = String(readData); // 將重量數據轉換為字串
  if (BMK52.getINT() == 0) {  // 檢查按鍵中斷
    unsigned int keyValue = BMK52.readKeyValue(); // 讀取按鍵值
    if (keyValue == 0b1) { // 如果按鍵1被按下，執行去皮操作
      uint8_t result = weight.calibrationZero(); // 執行去皮
      if (result == 0) {
        Serial.println("Tare: Success");
        BMD31.clearDisplay();
        BMD31.display();
        BMD31.setFont(FontTable_8X16);
        BMD31.drawString(0, 0, (u8*)"Tare Done");
        Serial.print("Weight: ");
        Serial.println(Weight);
      } else {
        Serial.println("Tare: Failed");
      }
    }
  }
}

// 檢查秤重感測器
void checkWeightSensor() {
  readData = weight.readWeight();
  // 如果重量超過 1000g，則開始上傳數據，並在重量低於 200g 時結束
  if (readData > 1000 && readData != previousData) {
    BMD31.clearDisplay(); // 清除顯示內容
    BMD31.display(); // 刷新顯示
    BMD31.setFont(FontTable_8X16); // 設置字體
    BMD31.drawString(0, 0, (u8*)"Stop Feeding"); // 顯示 "Stop Feeding"

    BMS36.motorForward(); // 馬達向前轉動
    delay(1000); // 馬達轉動 1 秒
    BMS36.motorStandby(); // 馬達待機

    while (readData > 200) {
      sendData(); // 上傳數據到 ThingSpeak
      delay(1000); // 每秒上傳一次數據
      readData = weight.readWeight(); // 更新重量數據
    }

    previousData = readData; // 更新上一次的重量數據

    // 重新顯示 "Ready"，表示流程重新開始
    BMD31.clearDisplay();
    BMD31.display();
    BMD31.setFont(FontTable_8X16);
    BMD31.drawString(0, 0, (u8*)"Ready");
  }
}

// 上傳數據到 ThingSpeak
void sendData() {
  String Weight = String(readData); // 將重量數據轉換為字串
  String DATA_BUF = "field1=" + Weight; // 構建上傳數據字串
  if (Wifi.writeString(DATA_BUF, PUBLISHTOPIC)) { // 發送數據
    Serial.print("Weight: ");
    Serial.println(Weight);
    Serial.println("Send String data success");
  } else {
    Serial.println("Send String data failed");
  }
}
