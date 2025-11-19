/***************************************************
  GY-906 (MLX90614) 紅外線溫度感測器程式
  
  腳位連接：
  - VCC => VDD3 (5V)
  - GND => GND
  - SDA => SDA (D18)
  - SCL => SCL (D19)
  
  功能：
  - 讀取物體溫度 (Object Temperature)
  - 讀取環境溫度 (Ambient Temperature)
  - Serial 輸出數據
 ****************************************************/

#include <Wire.h>
#include "GY906.h"

MLX90614 mlx;

// 感測器狀態
bool sensorReady = false;

void setup()
{
  Serial.begin(115200);
  Serial.println("GY-906 (MLX90614) 紅外線溫度感測器初始化中...");

  // 初始化標準 I2C (SDA=D18, SCL=D19)
  Wire.begin();
  
  // 初始化感測器
  if (!mlx.begin(Wire)) {
    Serial.println("錯誤：無法找到 GY-906 感測器！");
    Serial.println("請檢查連接：");
    Serial.println("  - SDA 連接到 SDA (D18)");
    Serial.println("  - SCL 連接到 SCL (D19)");
    Serial.println("  - VCC 連接到 VDD3 (5V)");
    Serial.println("  - GND 連接到 GND");
    Serial.println("  - 確認 I2C 地址是否為 0x5A");
    while (1); // 停止執行
  }

  Serial.println("GY-906 感測器已找到！");
  
  // 讀取感測器 ID
  uint16_t id = mlx.readID();
  Serial.print("感測器 ID: 0x");
  Serial.println(id, HEX);

  sensorReady = true;
  Serial.println("感測器配置完成！");
  Serial.println("開始讀取溫度數據...");
  Serial.println("==========================================");
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

  // 輸出溫度數據
  Serial.print("物體溫度: ");
  Serial.print(objectTemp, 2);
  Serial.print("°C");
  
  Serial.print("  |  環境溫度: ");
  Serial.print(ambientTemp, 2);
  Serial.println("°C");

  delay(500); // 延遲 500ms
}

