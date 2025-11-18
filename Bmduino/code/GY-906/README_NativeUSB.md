# GY-906 Native USB 測試程式說明

## 檔案說明

- **GY906_NativeUSB.ino** - 使用 Native USB (SerialUSB) 輸出的測試程式
- **GY906.h** - GY-906 感測器驅動庫（共用）

## 功能

- 使用 Native USB 介面進行通訊
- 讀取 GY-906 的兩個溫度值：
  - 物體溫度 (Object Temperature)
  - 環境溫度 (Ambient Temperature)
- 透過 USB CDC 輸出數據

## 使用步驟

### 1. 上傳程式

1. 打開 Arduino IDE
2. 打開 `GY906_NativeUSB.ino`
3. 選擇正確的開發板（BMduino-UNO）
4. 選擇上傳方式（使用 e-link32 或其他方式上傳）
5. 點擊上傳

### 2. 連接 Native USB

1. 將 BMduino 的 **Native USB** 介面連接到 PC
2. 等待 Windows 識別 USB 裝置
3. 在「裝置管理員」中查看新的 COM 埠（例如：COM3、COM4）

### 3. 查看輸出

#### 方法 1：使用 Arduino IDE Serial Monitor
1. 工具 → 序列埠監視器
2. 選擇 Native USB 對應的 COM 埠
3. 設定波特率：**115200**
4. 即可看到溫度數據輸出

#### 方法 2：使用 PuTTY
1. 開啟 PuTTY
2. Connection type → **Serial**
3. Serial line → 輸入 COM 埠（例如：`COM3`）
4. Speed → `115200`
5. 點擊 **Open**

#### 方法 3：使用 Python 腳本
```bash
cd Bmduino/tools
python serial_monitor.py COM3 115200
```

## 輸出格式

程式會輸出兩個溫度值，以逗號分隔：

```
25.50,23.20
25.51,23.21
25.52,23.22
```

格式：`物體溫度,環境溫度`

## 注意事項

1. **Native USB vs e-link32**
   - e-link32 使用 `Serial`（UART）
   - Native USB 使用 `SerialUSB`（USB CDC）
   - 兩者使用不同的 COM 埠

2. **供電**
   - Native USB 可以供電（使用 QC 2.0 充電器時會升壓到 12V）
   - 也可以只作為通訊介面使用

3. **驅動程式**
   - 首次連接時，Windows 可能需要安裝驅動程式
   - 通常會自動識別為 USB Serial Port

4. **COM 埠識別**
   - e-link32 和 Native USB 會顯示為不同的 COM 埠
   - 在裝置管理員中可以查看兩個不同的 COM 埠

## 測試確認

如果看到以下輸出，表示 Native USB 連接正常：

```
========================================
GY-906 (MLX90614) Native USB 測試
========================================
初始化中...
GY-906 感測器已找到！
感測器 ID: 0xXXXX
感測器配置完成！
開始讀取溫度數據...
========================================
格式：物體溫度,環境溫度
========================================
25.50,23.20
25.51,23.21
...
```

## 故障排除

### 問題：看不到 COM 埠
- 檢查 USB 線是否連接
- 檢查驅動程式是否已安裝
- 嘗試重新插拔 USB 線
- 在裝置管理員中查看是否有未識別的裝置

### 問題：看到亂碼
- 確認波特率設定為 **115200**
- 確認數據格式正確（8N1）

### 問題：沒有數據輸出
- 確認程式已上傳成功
- 確認 GY-906 感測器連接正確
- 檢查 I2C 連接（SDA/SCL）
- 確認感測器電源連接正確

