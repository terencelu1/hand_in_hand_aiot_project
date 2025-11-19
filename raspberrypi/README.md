# 智慧藥盒系統 - 樹莓派端

## 專案簡介

本系統為智慧藥盒健康監測系統的樹莓派端應用程式，負責：
- 與BMduino進行串口通訊，接收感測器數據
- 提供全螢幕UI界面，引導使用者完成服藥流程
- 使用電腦視覺技術檢測服藥動作
- 提供REST API供手機APP遠端監控

## 系統需求

- 樹莓派5
- Python 3.8+
- HDMI 2K螢幕
- USB攝影機
- BMduino連接（透過USB）

## 安裝步驟

### 1. 安裝系統依賴

```bash
sudo apt-get update
sudo apt-get install -y python3-pip python3-pyqt6 python3-opencv libopencv-dev libgl1-mesa-glx libglib2.0-0
```

### 2. 安裝Python套件

```bash
cd raspberrypi
pip3 install -r requirements.txt
```

或使用安裝腳本（會自動安裝所有依賴）：

```bash
chmod +x install.sh
./install.sh
```

### 3. 配置系統

編輯 `data/config.json` 設定：
- 串口路徑（預設：`/dev/ttyACM0`）
- 攝影機ID（預設：0）
- API端口（預設：5000）

編輯 `data/user_config.json` 設定使用者資訊。

### 4. 測試運行

```bash
chmod +x start.sh
./start.sh
```

## 自動啟動設置

### 方法1：使用systemd服務（推薦）

1. 複製服務檔案到系統目錄：

```bash
sudo cp smart-medicine-box.service /etc/systemd/system/
```

2. 修改服務檔案中的路徑（根據實際路徑調整）：

```bash
sudo nano /etc/systemd/system/smart-medicine-box.service
```

修改以下行：
- `WorkingDirectory`: 改為實際的專案路徑
- `ExecStart`: 改為實際的Python路徑和程式路徑
- `User`: 改為實際的使用者名稱

3. 重新載入systemd並啟用服務：

```bash
sudo systemctl daemon-reload
sudo systemctl enable smart-medicine-box.service
sudo systemctl start smart-medicine-box.service
```

4. 檢查服務狀態：

```bash
sudo systemctl status smart-medicine-box.service
```

5. 查看日誌：

```bash
sudo journalctl -u smart-medicine-box.service -f
```

### 方法2：使用rc.local（簡單但不推薦）

編輯 `/etc/rc.local`，在 `exit 0` 之前添加：

```bash
cd /home/pi/大手攜小手_code/raspberrypi
python3 program/main.py &
```

## 目錄結構

```
raspberrypi/
├── code/                    # 功能模組
│   ├── serial_communicator.py    # 串口通訊
│   ├── data_parser.py            # 數據解析
│   ├── database.py               # 數據庫操作
│   ├── user_mapper.py            # 使用者映射
│   └── cv_medication_detector.py # 服藥動作辨識
├── program/                 # 主程式
│   ├── main.py              # 程式入口
│   ├── main_ui.py           # UI應用
│   ├── state_machine.py     # 狀態機
│   └── api_server.py        # API服務器
├── data/                    # 數據和配置
│   ├── config.json          # 系統配置
│   ├── user_config.json     # 使用者配置
│   └── database.db          # SQLite數據庫（運行時生成）
├── models/                  # 模型檔案
├── requirements.txt          # Python依賴
├── start.sh                 # 啟動腳本
├── install.sh               # 安裝腳本
└── README.md               # 說明文件
```

## API接口

系統提供以下REST API接口（預設端口：5000）：

- `GET /api/status` - 獲取當前系統狀態
- `GET /api/latest?user_id=X` - 獲取最新測量數據
- `GET /api/history?user_id=X&limit=100` - 獲取歷史數據
- `GET /api/users` - 獲取使用者列表
- `GET /api/current_data` - 獲取當前感測器數據
- `GET /api/health` - 健康檢查

## 使用流程

1. **待機模式**：顯示時間、溫度、提示使用者放置指紋
2. **指紋辨識**：檢測到指紋後顯示使用者名稱
3. **心律血氧測量**：引導使用者放置手指，顯示實時數據
4. **取藥階段**：開啟對應藥盒，使用電腦視覺檢測服藥動作
5. **完成**：顯示完成訊息，返回待機模式

## 故障排除

### 串口連接失敗

- 檢查BMduino是否正確連接
- 確認串口路徑：`ls /dev/ttyACM*`
- 檢查使用者權限：`sudo usermod -a -G dialout $USER`（需要重新登入）

### 攝影機無法開啟

- 檢查USB攝影機連接：`lsusb`
- 確認攝影機ID：`v4l2-ctl --list-devices`
- 檢查權限：`sudo chmod 666 /dev/video0`

### UI無法顯示

- 檢查顯示器連接
- 確認PyQt6已正確安裝：`python3 -c "import PyQt6; print('OK')"`
- 檢查字體支援：確保系統有中文字體

### API無法訪問

- 檢查防火牆設定
- 確認端口未被占用：`sudo netstat -tulpn | grep 5000`
- 檢查WiFi連接狀態

## 日誌檔案

系統日誌保存在：`raspberrypi/data/system.log`

查看日誌：
```bash
tail -f raspberrypi/data/system.log
```

## 授權

本專案為「大手拉小手」競賽參賽作品。

## 聯絡資訊

如有問題或建議，歡迎提出 Issue。

