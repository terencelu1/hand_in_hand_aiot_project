#ifndef DHT11_H
#define DHT11_H

// DHT11 類別
class DHT11 {
public:
  DHT11(uint8_t pin);
  bool begin(void);
  bool read(float *humidity, float *temperature);
  float readHumidity(void);
  float readTemperature(void);
  
private:
  uint8_t _pin;
  uint8_t readByte(void);
  bool readData(uint8_t *data);
};

// DHT11 實作
DHT11::DHT11(uint8_t pin) {
  _pin = pin;
}

bool DHT11::begin(void) {
  pinMode(_pin, OUTPUT);
  digitalWrite(_pin, HIGH);
  delay(100);
  return true;
}

float DHT11::readHumidity(void) {
  float humidity = 0;
  float temperature = 0;
  if (read(&humidity, &temperature)) {
    return humidity;
  }
  return 0;
}

float DHT11::readTemperature(void) {
  float humidity = 0;
  float temperature = 0;
  if (read(&humidity, &temperature)) {
    return temperature;
  }
  return 0;
}

bool DHT11::read(float *humidity, float *temperature) {
  uint8_t data[5] = {0};
  
  if (!readData(data)) {
    return false;
  }
  
  // 校驗數據
  uint8_t checksum = data[0] + data[1] + data[2] + data[3];
  if (checksum != data[4]) {
    return false;
  }
  
  // 解析數據
  *humidity = (float)data[0] + (float)data[1] / 10.0;
  *temperature = (float)data[2] + (float)data[3] / 10.0;
  
  return true;
}

bool DHT11::readData(uint8_t *data) {
  // 發送啟動信號
  pinMode(_pin, OUTPUT);
  digitalWrite(_pin, LOW);
  delay(20);  // 至少 18ms
  digitalWrite(_pin, HIGH);
  delayMicroseconds(30);  // 20-40us
  
  // 切換為輸入模式
  pinMode(_pin, INPUT_PULLUP);
  
  // 等待感測器回應（拉低）
  uint32_t timeout = micros() + 100;
  while (digitalRead(_pin) == HIGH) {
    if (micros() > timeout) {
      return false;
    }
  }
  
  // 等待感測器拉高
  timeout = micros() + 100;
  while (digitalRead(_pin) == LOW) {
    if (micros() > timeout) {
      return false;
    }
  }
  
  // 等待感測器拉低（準備發送數據）
  timeout = micros() + 100;
  while (digitalRead(_pin) == HIGH) {
    if (micros() > timeout) {
      return false;
    }
  }
  
  // 讀取 40 位數據
  for (uint8_t i = 0; i < 5; i++) {
    data[i] = readByte();
  }
  
  return true;
}

uint8_t DHT11::readByte(void) {
  uint8_t byte = 0;
  
  for (uint8_t i = 0; i < 8; i++) {
    // 等待拉高（開始位）
    uint32_t timeout = micros() + 100;
    while (digitalRead(_pin) == LOW) {
      if (micros() > timeout) {
        return 0;
      }
    }
    
    // 測量高電平時間
    delayMicroseconds(30);
    
    // 判斷是 0 還是 1
    if (digitalRead(_pin) == HIGH) {
      byte |= (1 << (7 - i));
      
      // 等待拉低（結束位）
      timeout = micros() + 100;
      while (digitalRead(_pin) == HIGH) {
        if (micros() > timeout) {
          return 0;
        }
      }
    }
  }
  
  return byte;
}

#endif

