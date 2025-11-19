# Windows USB 串口監視指南

## 快速開始

### 方法 1：使用 Arduino IDE（最簡單）
1. 打開 Arduino IDE
2. 工具 → 序列埠監視器（Ctrl+Shift+M）
3. 選擇 COM 埠
4. 設定波特率（通常 115200）

### 方法 2：使用 PuTTY（推薦）
1. 下載 PuTTY：https://www.putty.org/
2. 開啟 PuTTY
3. Connection type → **Serial**
4. Serial line → 輸入 COM 埠（例如：`COM3`）
5. Speed → 輸入波特率（例如：`115200`）
6. 點擊 **Open**

### 方法 3：使用 Python 腳本
1. 安裝 pyserial：
   ```bash
   pip install pyserial
   ```
2. 運行腳本：
   ```bash
   python serial_monitor.py COM3 115200
   ```
   或直接運行，然後選擇串口

## 確認 Native 連接步驟

1. **連接 BMduino 到 PC**
   - 使用 USB 線連接 BMduino 到 Windows PC
   - 確認驅動程式已安裝

2. **確認 COM 埠**
   - 打開「裝置管理員」
   - 展開「連接埠 (COM 和 LPT)」
   - 記下 COM 埠號碼（例如：COM3）

3. **打開串口監視工具**
   - 使用上述任一方法打開串口監視器
   - 設定正確的 COM 埠和波特率

4. **測試連接**
   - 如果看到數據輸出，表示連接正常
   - 如果沒有輸出，檢查：
     - COM 埠是否正確
     - 波特率是否正確
     - USB 線是否正常
     - 驅動程式是否已安裝

## 常見問題

### Q: 找不到 COM 埠？
A: 
- 檢查 USB 線是否連接
- 檢查驅動程式是否已安裝
- 嘗試重新插拔 USB 線
- 在裝置管理員中查看是否有未識別的裝置

### Q: 看到亂碼？
A: 
- 檢查波特率設定是否正確（通常是 115200 或 9600）
- 確認數據格式（8N1：8 數據位，無校驗，1 停止位）

### Q: 沒有數據輸出？
A: 
- 確認程式已上傳到 BMduino
- 確認程式中有 Serial.begin() 和 Serial.print()
- 檢查程式是否在 loop() 中持續輸出
- 嘗試重新上傳程式

## 測試程式建議

當準備好測試時，可以使用簡單的測試程式：

```cpp
void setup() {
  Serial.begin(115200);
  Serial.println("BMduino Native 連接測試");
  Serial.println("如果看到這行，表示連接成功！");
}

void loop() {
  Serial.print("時間: ");
  Serial.println(millis() / 1000);
  delay(1000);
}
```

