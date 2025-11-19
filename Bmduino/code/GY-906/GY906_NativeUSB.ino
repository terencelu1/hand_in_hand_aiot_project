/***************************************************
  GY-906 (MLX90614) Native USB 測試程式
  
  腳位連接：
  - VCC => VDD3 (5V)
  - GND => GND
  - SDA => SDA (D18)
  - SCL => SCL (D19)
  
  功能：
  - 使用 Native USB (SerialUSB) 輸出
  - 讀取物體溫度 (Object Temperature)
  - 讀取環境溫度 (Ambient Temperature)
  - 透過 USB CDC 輸出數據
  
  注意：
  - 此程式使用 Native USB 介面
  - 連接 PC 後會顯示為 USB Serial Port (COMx)
  - 使用 SerialUSB 而不是 Serial
  ****************************************************/

#include <Wire.h>
#include "GY906.h"

MLX90614 mlx;

// 感測器狀態
bool sensorReady = false;

void setup()
{
  // 初始化 Native USB (SerialUSB)
  SerialUSB.begin(115200);
  
  // 等待 USB 連接（可選，如果不需要等待可以註解掉）
  // while (!SerialUSB) {
  //   ; // 等待 USB 連接
  // }
  
  delay(1000); // 等待 USB 初始化完成
  
  SerialUSB.println("========================================");
  SerialUSB.println("GY-906 (MLX90614) Native USB 測試");
  SerialUSB.println("========================================");
  SerialUSB.println("初始化中...");

  // 初始化標準 I2C (SDA=D18, SCL=D19)
  Wire.begin();
  
  // 初始化感測器
  if (!mlx.begin(Wire)) {
    SerialUSB.println("錯誤：無法找到 GY-906 感測器！");
    SerialUSB.println("請檢查連接：");
    SerialUSB.println("  - SDA 連接到 SDA (D18)");
    SerialUSB.println("  - SCL 連接到 SCL (D19)");
    SerialUSB.println("  - VCC 連接到 VDD3 (5V)");
    SerialUSB.println("  - GND 連接到 GND");
    SerialUSB.println("  - 確認 I2C 地址是否為 0x5A");
    while (1); // 停止執行
  }

  SerialUSB.println("GY-906 感測器已找到！");
  
  // 讀取感測器 ID
  uint16_t id = mlx.readID();
  SerialUSB.print("感測器 ID: 0x");
  SerialUSB.println(id, HEX);

  sensorReady = true;
  SerialUSB.println("感測器配置完成！");
  SerialUSB.println("開始讀取溫度數據...");
  SerialUSB.println("========================================");
  SerialUSB.println("格式：物體溫度,環境溫度");
  SerialUSB.println("========================================");
  delay(1000);
}

void loop()
{
  if (!sensorReady) {
    return;
  }

  // 讀取物體溫度（感測器指向的物體）
  float objectTemp = mlx.readObjectTemp();
  
  // 讀取環境溫度（感測器周圍環境）
  float ambientTemp = mlx.readAmbientTemp();

  // 輸出兩個溫度值（簡潔格式，方便解析）
  SerialUSB.print(objectTemp, 2);
  SerialUSB.print(",");
  SerialUSB.println(ambientTemp, 2);

  delay(500); // 延遲 500ms
}

