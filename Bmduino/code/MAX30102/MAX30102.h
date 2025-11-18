#ifndef MAX30102_H
#define MAX30102_H

#include <Wire.h>
#include <math.h>

// I2C 速度定義
#define I2C_SPEED_STANDARD 100000
#define I2C_SPEED_FAST 400000

// MAX30102 寄存器地址
#define REG_INTR_STATUS_1    0x00
#define REG_INTR_STATUS_2    0x01
#define REG_INTR_ENABLE_1    0x02
#define REG_INTR_ENABLE_2    0x03
#define REG_FIFO_WR_PTR      0x04
#define REG_OVF_COUNTER      0x05
#define REG_FIFO_RD_PTR      0x06
#define REG_FIFO_DATA        0x07
#define REG_FIFO_CONFIG      0x08
#define REG_MODE_CONFIG      0x09
#define REG_SPO2_CONFIG      0x0A
#define REG_LED1_PA          0x0C
#define REG_LED2_PA          0x0D
#define REG_PILOT_PA         0x10
#define REG_MULTI_LED_CTRL1  0x11
#define REG_MULTI_LED_CTRL2  0x12
#define REG_TEMP_INTR        0x1F
#define REG_TEMP_FRAC        0x20
#define REG_TEMP_CONFIG      0x21
#define REG_REV_ID           0xFE
#define REG_PART_ID          0xFF

// MAX30102 I2C 地址
#define MAX30102_ADDRESS     0x57

// MAX30105 類別（用於 MAX30102）
class MAX30105 {
public:
  MAX30105();
  bool begin(TwoWire &wirePort = Wire, uint32_t i2cSpeed = I2C_SPEED_STANDARD);
  void setup(byte powerLevel = 0x1F, byte sampleAverage = 4, byte ledMode = 3, int sampleRate = 400, int pulseWidth = 411, int adcRange = 4096);
  long getIR(void);
  long getRed(void);
  void softReset(void);
  void shutdown(void);
  void wakeUp(void);
  
private:
  TwoWire *_i2cPort;
  uint8_t _i2caddr;
  void readRegister(uint8_t address, uint8_t *value);
  void writeRegister(uint8_t address, uint8_t value);
  void readFIFO(void);
  
  uint32_t red;
  uint32_t IR;
};

// MAX30105 實作
MAX30105::MAX30105() {
  _i2caddr = MAX30102_ADDRESS;
  red = 0;
  IR = 0;
}

bool MAX30105::begin(TwoWire &wirePort, uint32_t i2cSpeed) {
  _i2cPort = &wirePort;
  _i2cPort->begin();
  _i2cPort->setClock(i2cSpeed);
  
  // 檢查感測器是否存在
  uint8_t partId;
  readRegister(REG_PART_ID, &partId);
  
  if (partId != 0x15) { // MAX30102 的 PART_ID 是 0x15
    return false;
  }
  
  return true;
}

void MAX30105::setup(byte powerLevel, byte sampleAverage, byte ledMode, int sampleRate, int pulseWidth, int adcRange) {
  softReset();
  delay(100);
  
  // FIFO 配置
  byte fifoConfig = (sampleAverage << 5) | 0x0F; // 樣本平均數 + FIFO 滾動
  writeRegister(REG_FIFO_CONFIG, fifoConfig);
  
  // 模式配置
  writeRegister(REG_MODE_CONFIG, ledMode);
  
  // SpO2 配置
  byte spo2Config = 0;
  if (sampleRate == 50) spo2Config |= 0x00;
  else if (sampleRate == 100) spo2Config |= 0x04;
  else if (sampleRate == 200) spo2Config |= 0x08;
  else if (sampleRate == 400) spo2Config |= 0x0C;
  else if (sampleRate == 800) spo2Config |= 0x10;
  else if (sampleRate == 1000) spo2Config |= 0x14;
  else if (sampleRate == 1600) spo2Config |= 0x18;
  else if (sampleRate == 3200) spo2Config |= 0x1C;
  
  if (pulseWidth == 69) spo2Config |= 0x00;
  else if (pulseWidth == 118) spo2Config |= 0x01;
  else if (pulseWidth == 215) spo2Config |= 0x02;
  else if (pulseWidth == 411) spo2Config |= 0x03;
  
  if (adcRange == 2048) spo2Config |= 0x00;
  else if (adcRange == 4096) spo2Config |= 0x20;
  else if (adcRange == 8192) spo2Config |= 0x40;
  else if (adcRange == 16384) spo2Config |= 0x60;
  
  writeRegister(REG_SPO2_CONFIG, spo2Config);
  
  // LED 功率配置
  writeRegister(REG_LED1_PA, powerLevel); // Red LED
  writeRegister(REG_LED2_PA, powerLevel); // IR LED
  
  // 啟用 FIFO
  writeRegister(REG_FIFO_WR_PTR, 0x00);
  writeRegister(REG_OVF_COUNTER, 0x00);
  writeRegister(REG_FIFO_RD_PTR, 0x00);
}

long MAX30105::getIR(void) {
  readFIFO();
  return IR;
}

long MAX30105::getRed(void) {
  readFIFO();
  return red;
}

void MAX30105::softReset(void) {
  writeRegister(REG_MODE_CONFIG, 0x40);
}

void MAX30105::shutdown(void) {
  uint8_t mode;
  readRegister(REG_MODE_CONFIG, &mode);
  writeRegister(REG_MODE_CONFIG, mode | 0x80);
}

void MAX30105::wakeUp(void) {
  uint8_t mode;
  readRegister(REG_MODE_CONFIG, &mode);
  writeRegister(REG_MODE_CONFIG, mode & 0x7F);
}

void MAX30105::readRegister(uint8_t address, uint8_t *value) {
  _i2cPort->beginTransmission(_i2caddr);
  _i2cPort->write(address);
  _i2cPort->endTransmission(false);
  _i2cPort->requestFrom(_i2caddr, (uint8_t)1);
  *value = _i2cPort->read();
}

void MAX30105::writeRegister(uint8_t address, uint8_t value) {
  _i2cPort->beginTransmission(_i2caddr);
  _i2cPort->write(address);
  _i2cPort->write(value);
  _i2cPort->endTransmission();
}

void MAX30105::readFIFO(void) {
  uint8_t temp[6];
  uint32_t tempLong;
  
  _i2cPort->beginTransmission(_i2caddr);
  _i2cPort->write(REG_FIFO_DATA);
  _i2cPort->endTransmission(false);
  _i2cPort->requestFrom(_i2caddr, (uint8_t)6);
  
  for (uint8_t i = 0; i < 6; i++) {
    temp[i] = _i2cPort->read();
  }
  
  // 組合數據 (18位)
  tempLong = (long)temp[0] << 16;
  tempLong |= (long)temp[1] << 8;
  tempLong |= (long)temp[2];
  tempLong &= 0x03FFFF; // 只取 18 位
  red = tempLong;
  
  tempLong = (long)temp[3] << 16;
  tempLong |= (long)temp[4] << 8;
  tempLong |= (long)temp[5];
  tempLong &= 0x03FFFF; // 只取 18 位
  IR = tempLong;
}

// 心率檢測變數（靜態變數）
static int32_t threshold = 0;
static bool firstBeat = true;
static bool secondBeat = false;
static int32_t beatLast = 0;
static int32_t lastTime = 0;
static int32_t peak = 0;
static int32_t trough = 0;
static int32_t amp = 0;
static bool rising = false;
static int32_t riseCount = 0;
static int32_t lastSample = 0;
static int32_t sampleCount = 0;

// 心率檢測函數（改進版）
bool checkForBeat(int32_t sample) {
  bool beatDetected = false;
  
  // 初始化閾值（使用前幾個樣本的平均值）
  if (threshold == 0 && sampleCount < 10) {
    threshold += sample;
    sampleCount++;
    if (sampleCount == 10) {
      threshold = threshold / 10;
    }
    lastSample = sample;
    return false;
  }
  
  // 如果閾值還沒初始化，使用樣本值
  if (threshold == 0) {
    threshold = sample;
  }
  
  // 檢測上升沿（從低於閾值到高於閾值）
  if (sample > threshold && lastSample <= threshold && rising == false) {
    rising = true;
    peak = sample;
    trough = lastSample;
  }
  
  // 檢測下降沿（從高於閾值到低於閾值）- 這表示一個心跳
  if (sample < threshold && lastSample >= threshold && rising == true) {
    rising = false;
    amp = peak - trough;
    if (amp > 1000) { // 確保有足夠的振幅
      threshold = (peak + trough) / 2; // 動態調整閾值
      beatDetected = true;
    }
  }
  
  // 更新峰值和谷值
  if (rising && sample > peak) {
    peak = sample;
  }
  if (!rising && (sample < trough || trough == 0)) {
    trough = sample;
  }
  
  lastSample = sample;
  return beatDetected;
}

// 血氧演算法函數
void maxim_heart_rate_and_oxygen_saturation(
  uint32_t *pun_ir_buffer,
  int32_t n_ir_buffer_length,
  uint32_t *pun_red_buffer,
  int32_t *pn_spo2,
  int8_t *pch_spo2_valid,
  int32_t *pn_heart_rate,
  int8_t *pch_hr_valid
) {
  // 簡化版本：計算紅光和紅外光的比值來估算血氧
  *pch_spo2_valid = 0;
  *pch_hr_valid = 0;
  *pn_spo2 = 0;
  *pn_heart_rate = 0;
  
  if (n_ir_buffer_length < 25) {
    return; // 數據不足
  }
  
  // 計算平均值
  uint32_t ir_mean = 0;
  uint32_t red_mean = 0;
  
  for (int32_t i = 0; i < n_ir_buffer_length; i++) {
    ir_mean += pun_ir_buffer[i];
    red_mean += pun_red_buffer[i];
  }
  
  ir_mean /= n_ir_buffer_length;
  red_mean /= n_ir_buffer_length;
  
  if (ir_mean == 0 || red_mean == 0) {
    return;
  }
  
  // 計算 AC/DC 比值
  uint32_t ir_ac = 0;
  uint32_t red_ac = 0;
  
  for (int32_t i = 1; i < n_ir_buffer_length; i++) {
    int32_t ir_diff = (int32_t)pun_ir_buffer[i] - (int32_t)pun_ir_buffer[i-1];
    int32_t red_diff = (int32_t)pun_red_buffer[i] - (int32_t)pun_red_buffer[i-1];
    ir_ac += abs(ir_diff);
    red_ac += abs(red_diff);
  }
  
  if (ir_mean > 0 && red_mean > 0) {
    float ratio = ((float)red_ac / red_mean) / ((float)ir_ac / ir_mean);
    
    // 簡化的血氧計算公式
    if (ratio > 0.4 && ratio < 1.5) {
      *pn_spo2 = (int32_t)(110 - 25 * ratio);
      if (*pn_spo2 >= 70 && *pn_spo2 <= 100) {
        *pch_spo2_valid = 1;
      }
    }
  }
  
  // 改進的心率計算（基於峰值檢測和週期分析）
  int32_t peaks = 0;
  int32_t lastPeakIndex = -1;
  int32_t peakIntervals[10];
  int32_t intervalCount = 0;
  
  // 計算動態閾值（平均值 + 標準差）
  uint32_t sumSqDiff = 0;
  for (int32_t i = 0; i < n_ir_buffer_length; i++) {
    int32_t diff = (int32_t)pun_ir_buffer[i] - (int32_t)ir_mean;
    sumSqDiff += diff * diff;
  }
  uint32_t variance = sumSqDiff / n_ir_buffer_length;
  uint32_t stdDev = sqrt(variance);
  uint32_t dynamicThreshold = ir_mean + stdDev * 0.5;
  
  // 檢測峰值
  for (int32_t i = 1; i < n_ir_buffer_length - 1; i++) {
    if (pun_ir_buffer[i] > pun_ir_buffer[i-1] && 
        pun_ir_buffer[i] > pun_ir_buffer[i+1] &&
        pun_ir_buffer[i] > dynamicThreshold) {
      peaks++;
      
      // 計算峰值間隔
      if (lastPeakIndex >= 0 && intervalCount < 10) {
        peakIntervals[intervalCount++] = i - lastPeakIndex;
      }
      lastPeakIndex = i;
    }
  }
  
  // 使用峰值間隔計算心率（更準確）
  if (intervalCount >= 2) {
    // 計算平均間隔
    int32_t avgInterval = 0;
    for (int32_t i = 0; i < intervalCount; i++) {
      avgInterval += peakIntervals[i];
    }
    avgInterval /= intervalCount;
    
    // 假設採樣時間為 100ms
    float timePerSample = 0.1; // 秒
    float intervalSeconds = avgInterval * timePerSample;
    *pn_heart_rate = (int32_t)(60.0 / intervalSeconds);
    
    if (*pn_heart_rate >= 50 && *pn_heart_rate <= 200) {
      *pch_hr_valid = 1;
    }
  } else if (peaks > 0) {
    // 備用方法：使用峰值數量估算
    float time_seconds = n_ir_buffer_length * 0.1;
    *pn_heart_rate = (int32_t)((peaks / time_seconds) * 60);
    if (*pn_heart_rate >= 50 && *pn_heart_rate <= 200) {
      *pch_hr_valid = 1;
    }
  }
}

#endif

