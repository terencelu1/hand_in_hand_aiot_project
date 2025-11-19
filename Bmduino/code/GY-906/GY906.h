#ifndef GY906_H
#define GY906_H

#include <Wire.h>

// MLX90614 I2C 地址
#define MLX90614_ADDRESS 0x5A

// MLX90614 寄存器地址
#define MLX90614_REG_TA      0x06  // 環境溫度
#define MLX90614_REG_TOBJ1   0x07  // 物體溫度 1
#define MLX90614_REG_TOBJ2   0x08  // 物體溫度 2
#define MLX90614_REG_TOMAX   0x20  // 最大溫度
#define MLX90614_REG_TOMIN   0x21  // 最小溫度
#define MLX90614_REG_PWMCTRL 0x22  // PWM 控制
#define MLX90614_REG_CONFIG  0x24  // 配置寄存器
#define MLX90614_REG_EMISS   0x04  // 發射率
#define MLX90614_REG_ID1     0x3C  // ID 低位
#define MLX90614_REG_ID2     0x3D  // ID 高位
#define MLX90614_REG_ID3     0x3E  // ID 控制位
#define MLX90614_REG_ID4     0x3F  // ID 高位

// MLX90614 類別
class MLX90614 {
public:
  MLX90614(uint8_t address = MLX90614_ADDRESS);
  bool begin(TwoWire &wirePort = Wire);
  float readObjectTemp(void);
  float readAmbientTemp(void);
  uint16_t readID(void);
  
private:
  TwoWire *_i2cPort;
  uint8_t _i2caddr;
  uint16_t read16(uint8_t reg);
  void write16(uint8_t reg, uint16_t data);
  float readTemp(uint8_t reg);
};

// MLX90614 實作
MLX90614::MLX90614(uint8_t address) {
  _i2caddr = address;
}

bool MLX90614::begin(TwoWire &wirePort) {
  _i2cPort = &wirePort;
  
  // 嘗試讀取 ID 來驗證感測器是否存在
  uint16_t id = readID();
  if (id == 0x0000 || id == 0xFFFF) {
    return false;
  }
  
  return true;
}

float MLX90614::readObjectTemp(void) {
  return readTemp(MLX90614_REG_TOBJ1);
}

float MLX90614::readAmbientTemp(void) {
  return readTemp(MLX90614_REG_TA);
}

uint16_t MLX90614::readID(void) {
  uint16_t id1 = read16(MLX90614_REG_ID1);
  uint16_t id2 = read16(MLX90614_REG_ID2);
  return (id2 << 8) | id1;
}

float MLX90614::readTemp(uint8_t reg) {
  uint16_t data = read16(reg);
  
  // MLX90614 溫度數據格式：16 位，單位為 0.02°C
  // 實際溫度 = 數據 * 0.02 - 273.15
  float temp = (float)data * 0.02;
  temp = temp - 273.15;
  
  return temp;
}

uint16_t MLX90614::read16(uint8_t reg) {
  uint16_t data = 0;
  
  _i2cPort->beginTransmission(_i2caddr);
  _i2cPort->write(reg);
  if (_i2cPort->endTransmission(false) != 0) {
    return 0; // 錯誤
  }
  
  _i2cPort->requestFrom(_i2caddr, (uint8_t)3);
  
  if (_i2cPort->available() >= 3) {
    uint8_t lsb = _i2cPort->read();
    uint8_t msb = _i2cPort->read();
    uint8_t pec = _i2cPort->read(); // PEC (Packet Error Code)，這裡不使用
    
    data = (uint16_t)msb << 8 | lsb;
  }
  
  return data;
}

void MLX90614::write16(uint8_t reg, uint16_t data) {
  _i2cPort->beginTransmission(_i2caddr);
  _i2cPort->write(reg);
  _i2cPort->write(data & 0xFF);        // LSB
  _i2cPort->write((data >> 8) & 0xFF);  // MSB
  _i2cPort->endTransmission();
}

#endif

