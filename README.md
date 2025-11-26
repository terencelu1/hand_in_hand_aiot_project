# 大手拉小手 - 智慧藥盒健康監測系統

## 📱 快速下載 APP

**Android APK 直接下載：**
[![Download APK](https://img.shields.io/badge/Download-APK-brightgreen?style=for-the-badge&logo=android)](https://github.com/terencelu1/hand_in_hand_aiot_project/raw/main/Flutter_App_LiquidGlass.apk)

**APK 資訊：**
- 版本：1.0.0
- 大小：22.4 MB
- 最低 Android 版本：Android 5.0 (API 21)
- 架構：arm64-v8a, armeabi-v7a, x86_64

**安裝說明：**
1. 點擊上方按鈕下載 APK
2. 在手機設定中啟用「允許安裝未知來源的應用」
3. 開啟下載的 APK 檔案進行安裝
4. 安裝完成後，進入「設定」頁面，點擊「伺服器 IP 地址」設定您的樹莓派 IP（預設：10.23.220.34）

---

## 專案簡介

本專案為「大手拉小手」競賽參賽作品，開發整合式智慧藥盒健康監測系統。採用 BMduino (BM53A367A) 作為核心控制平台，整合 AS608 指紋辨識、MAX30102 心率血氧感測器、GY-906 溫度感測器與四路繼電器模組，實現身份驗證、生理參數監測與智慧控制功能。

系統採用三模式運作：待機模式持續監控感測器數據；工作模式於指紋辨識成功後啟動，進行精確的生理參數測量；接收模式處理樹莓派控制命令，執行繼電器動作。所有數據透過 Native USB 介面以標準化通訊協議與樹莓派進行即時傳輸，為智慧醫療與健康照護應用提供可靠的技術基礎。

## 系統架構

```
BMduino (感測器整合) ←→ 樹莓派 (數據處理/REST API) ←→ Flutter APP (行動監控)
```

## 主要功能

### 硬體端 (BMduino)
- **身份辨識**：AS608 指紋辨識模組
- **生理監測**：MAX30102 心率血氧感測器
- **溫度監控**：GY-906 非接觸式溫度感測器
- **智慧控制**：四路繼電器模組（電磁鎖控制）
- **數據通訊**：Native USB 串口通訊（115200 baud）

### 後端 (樹莓派)
- **數據處理**：接收並處理 BMduino 感測器數據
- **REST API 服務**：提供 HTTP API 供行動端存取 (Port 5000)
- **數據庫管理**：儲存歷史記錄和用戶資訊
- **CV 藥物辨識**：使用計算機視覺進行藥物檢測

### 前端 (Flutter APP)
- **即時監控**：顯示即時心率、血氧、環境溫濕度
- **趨勢圖表**：動態圖表顯示 7 天生理數據趨勢
- **數據分析**：5 天詳細數據分析和統計
- **病患管理**：支援多病患切換和管理
- **毛玻璃 UI**：現代化的 Liquid Glass 設計風格

## 專案結構

```
hand_in_hand_aiot_project/
├── Bmduino/                  # BMduino 硬體程式
│   ├── code/                 # 各感測器獨立程式
│   ├── program/              # 整合主程式
│   └── reference/            # 參考資料
├── raspberrypi/              # 樹莓派端程式
│   ├── code/                 # 核心功能模組（串口通訊、數據庫、CV檢測等）
│   ├── program/              # 主程式（UI、API服務器、狀態機）
│   ├── data/                 # 配置文件和數據庫
│   └── reference/            # 參考資料
├── flutter_application_1liduid/  # Flutter 手機 APP
│   ├── lib/
│   │   ├── models/           # 數據模型
│   │   ├── services/         # API 服務和數據倉儲
│   │   ├── providers/        # Riverpod 狀態管理
│   │   └── ui/               # UI 頁面和組件
│   ├── android/              # Android 配置
│   ├── ios/                  # iOS 配置
│   └── build/                # 編譯輸出
└── reference/                # 專案參考文件
```

## 快速開始

### 硬體需求

- BMduino (BM53A367A) 開發板
- AS608 指紋辨識模組
- MAX30102 心率血氧感測器
- GY-906 溫度感測器
- 四路繼電器模組
- 樹莓派（用於數據處理）

### 軟體需求

- Arduino IDE
- Python 3.x
- Flutter SDK
- Android Studio (可選)

### 安裝步驟

#### 1. BMduino 設置
```bash
# 上傳整合程式至 BMduino
# 使用 Arduino IDE 開啟 Bmduino/program/BMduino_Integrated.ino
# 選擇 BM53A367A 開發板並上傳
```

#### 2. 樹莓派設置
```bash
cd raspberrypi
chmod +x install.sh
./install.sh

# 啟動 API 服務器
python program/api_server.py
```

#### 3. Flutter APP 設置
```bash
cd flutter_application_1liduid

# 安裝依賴
flutter pub get

# 運行應用
flutter run

# 或打包 APK
flutter build apk --release
```

## API 端點

樹莓派 REST API 運行於 `http://[樹莓派IP]:5000`

主要端點：
- `GET /health` - 健康檢查
- `GET /status` - 系統狀態
- `GET /users` - 獲取用戶列表
- `GET /api/current` - 獲取當前數據
- `GET /api/latest/<user_id>` - 獲取最新記錄
- `GET /api/history/<user_id>` - 獲取歷史記錄

詳細 API 文檔：[API 使用說明](raspberrypi/API使用說明.md)

## 📱 Flutter APP 功能

### 首頁 (Dashboard)
- 即時顯示當前選定病患的生理數據
- 7 天心率/血氧趨勢圖表
- 環境溫濕度監控
- 快速切換不同病患

### 分析頁 (Analytics)
- 5 天詳細趨勢分析
- 心率、血氧、溫度、濕度獨立圖表
- 服藥依從性統計
- 數據總覽和異常提醒

### 病患管理頁
- 查看所有病患列表
- 切換當前監控對象
- 顯示病患基本資訊

### 🎨 UI 特色
- **Liquid Glass 設計**：現代化毛玻璃質感
- **漸變背景**：紫色到青色的動態漸變
- **動態圖表**：以 10 為單位的 Y 軸刻度，自動適應數據範圍
- **即時更新**：與樹莓派 REST API 無縫整合

### 📸 APP 截圖
> 註：可在此添加 APP 截圖以展示介面

## 通訊協議

詳細通訊協議請參考：[通訊協議文檔](Bmduino/program/通訊協議.md)

## 技術棧

### 硬體端
- C/C++ (Arduino)
- BMduino SDK

### 後端
- Python 3.x
- Flask (REST API)
- SQLite (數據庫)
- OpenCV (計算機視覺)
- pyserial (串口通訊)

### 前端
- Flutter/Dart
- Riverpod (狀態管理)
- fl_chart (圖表庫)
- http (網路請求)

## 開發團隊

「大手拉小手」競賽團隊

## 授權

本專案為「大手拉小手」競賽參賽作品。

## 聯絡資訊

如有問題或建議，歡迎提出 Issue 或 Pull Request。

---

最後更新：2025-01-27

## 更新日誌

### v1.0.0 (2025-01-27)
- ✨ 新增：可在設定頁面動態設定伺服器 IP 地址
- 🔧 改進：IP 地址設定會自動保存，無需重新編譯應用
- 🐛 修復：優化 API 服務的 IP 配置管理
