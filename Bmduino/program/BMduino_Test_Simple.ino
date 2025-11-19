/***************************************************
  BMduino 簡單測試程式
  用於測試 Native USB 是否正常運作
  ****************************************************/

void setup() {
  // 初始化 Native USB
  SerialUSB.begin(115200);
  
  // 等待 USB 連接（可選）
  // while (!SerialUSB) {
  //   delay(10);
  // }
  
  delay(1000); // 等待 USB 初始化完成
  
  SerialUSB.println("========================================");
  SerialUSB.println("BMduino 簡單測試程式");
  SerialUSB.println("========================================");
  SerialUSB.println("如果看到這條訊息，表示 USB 通訊正常！");
  SerialUSB.println("========================================");
}

void loop() {
  // 每秒輸出一次測試訊息
  SerialUSB.println("測試訊息 - 系統正常運作");
  delay(1000);
}

