#include "BMS56M605.h"         // 包含 BMS56M605 加速度感測器模組
#include "ThingSpeakPublish.h" // 包含 ThingSpeak 上傳模組
#include "BMD31M090.h"         // 包含 OLED 顯示模組
#include "Timer.h"             // 包含 Timer 模組

// 定義 OLED 顯示模組的參數
#define BMD31M090_WIDTH 128     // OLED 顯示寬度，單位：像素
#define BMD31M090_HEIGHT 64     // OLED 顯示高度，單位：像素
#define BMD31M090_ADDRESS 0x3C  // OLED I2C 通訊地址

// 初始化模組
BMS56M605 Mpu(8);                                           // 設定 BMS56M605 感測器，使用 pin 8 作為中斷引腳
BMC81M001 Wifi(&Serial3);                                   // 初始化 WiFi 模組（替換 Serial3 為實際使用的串口）
BMD31M090 BMD31(BMD31M090_WIDTH, BMD31M090_HEIGHT, &Wire);  // 初始化 OLED 顯示模組

Timer t;           // Timer 物件，用於定期執行任務
uint16_t cnt = 0;  // 計數器，用於記錄偵測到的運動次數

void setup() {
    Mpu.begin();              // 初始化加速度感測器
    Serial.begin(9600);       // 初始化序列埠通信
    
    // 設定運動偵測參數
    Mpu.setINT(MOTION_MODE, true);              // 啟用運動模式
    Mpu.setInterruptPinPolarity(ACTIVE_LOW);    // 設定中斷引腳在無中斷時為低電平
    Mpu.setMotionThreshold(1);                  // 設定運動閾值為 1 mg
    Mpu.setMotionDuration(30);                  // 設定運動持續時間為 30 ms

    // 初始化 OLED 顯示模組
    BMD31.begin(BMD31M090_ADDRESS); // 開始 OLED 模組
    BMD31.clearDisplay();            // 清除顯示
    BMD31.display();                 // 刷新顯示
    BMD31.setFont(FontTable_8X16);   // 設定顯示字體
    BMD31.drawString(0, displayROW2, (u8*)"Motion Detected x"); // 顯示初始信息

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

    delay(200);                          // 延遲以確保連接穩定
    Wifi.setPublishTopic(PUBLISHTOPIC);  // 設定上傳主題

    // 使用 Timer 每隔 1000 毫秒執行一次讀取和上傳數據的任務
    t.every(1000, readAndUploadData);
}

void loop() {
    t.update();           // 更新 Timer，執行定時任務
    checkMotionStatus();  // 不斷檢查是否有運動發生
}

// 讀取加速度數據並上傳至 ThingSpeak 的函數
void readAndUploadData() {
    Mpu.getEvent();  // 取得感測器事件數據
    Serial.print("ax = ");
    Serial.print(Mpu.accX);  // 打印 X 軸加速度數據
    Serial.println();

    // 構建要上傳到 ThingSpeak 的數據字串
    String AccX = String(Mpu.accX);      // 將加速度數據轉換為字串
    String DATA_BUF = "field1=" + AccX;  // 構建數據字串

    // 發送數據到 ThingSpeak
    if (Wifi.writeString(DATA_BUF, PUBLISHTOPIC)) {  // 發送數據
        Serial.println("Send String data success");
    } else {
        Serial.println("Send String data failed");
    }
}

// 持續檢查運動狀態並在 OLED 上顯示的函數
void checkMotionStatus() {
    if (Mpu.getINT() == 0) {  // 如果有運動中斷
        cnt++;  // 運動次數累加
        if (cnt >= 0xffff) cnt = 0;  // 防止計數器溢出

        // 更新 OLED 顯示運動偵測信息
        BMD31.clearDisplay();  // 清除顯示
        BMD31.display();       // 刷新顯示
        BMD31.setFont(FontTable_8X16);                  // 設定顯示字體
        BMD31.drawString(0, displayROW2, (u8*)"Motion Detected x"); // 顯示 "Motion Detected x"
        char buffer[10];
        snprintf(buffer, sizeof(buffer), "%d", cnt);  // 將計數器轉換為字串
        BMD31.drawString(48, displayROW4, (u8*)buffer);        // 顯示運動次數
        Serial.print("Motion Detected!  x");
        Serial.println(cnt);
        Serial.println();
    }
}
