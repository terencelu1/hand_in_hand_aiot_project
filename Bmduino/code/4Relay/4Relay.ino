// --- Relay pin define ---
const int relay1 = 2;   // IN1
const int relay2 = 3;   // IN2
const int relay3 = 4;   // IN3
const int relay4 = 5;   // IN4

void setup() {
  // set all relay pins to OUTPUT
  pinMode(relay1, OUTPUT);
  pinMode(relay2, OUTPUT);
  pinMode(relay3, OUTPUT);
  pinMode(relay4, OUTPUT);

  // make sure all relays start OFF (HIGH = OFF on low-trigger boards)
  digitalWrite(relay1, HIGH);
  digitalWrite(relay2, HIGH);
  digitalWrite(relay3, HIGH);
  digitalWrite(relay4, HIGH);
}

void loop() {
  activateRelay(relay1);
  activateRelay(relay2);
  activateRelay(relay3);
  activateRelay(relay4);
}

// 函式：打開指定 relay 1 秒、關閉 1 秒
void activateRelay(int relayPin) {
  // 確保其他都關閉（安全）
  allRelaysOff();

  // 開啟指定鎖（LOW = ON）
  digitalWrite(relayPin, LOW);
  delay(1000);   // 打開 1 秒

  // 關閉（HIGH = OFF）
  digitalWrite(relayPin, HIGH);
  delay(1000);   // 關閉 1 秒
}

// 將所有繼電器關閉（確保一次只開 1 個）
void allRelaysOff() {
  digitalWrite(relay1, HIGH);
  digitalWrite(relay2, HIGH);
  digitalWrite(relay3, HIGH);
  digitalWrite(relay4, HIGH);
}
