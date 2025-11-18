# 大手拉小手 - 智慧藥盒健康監測系統

## 專案簡介

本專案為「大手拉小手」競賽參賽作品，開發整合式智慧藥盒健康監測系統。採用 BMduino (BM53A367A) 作為核心控制平台，整合 AS608 指紋辨識、MAX30102 心率血氧感測器、GY-906 溫度感測器與四路繼電器模組，實現身份驗證、生理參數監測與智慧控制功能。

系統採用三模式運作：待機模式持續監控感測器數據；工作模式於指紋辨識成功後啟動，進行精確的生理參數測量；接收模式處理樹莓派控制命令，執行繼電器動作。所有數據透過 Native USB 介面以標準化通訊協議與樹莓派進行即時傳輸，為智慧醫療與健康照護應用提供可靠的技術基礎。

## 系統架構

```
BMduino (感測器整合) ←→ 樹莓派 (數據處理) ←→ 行動應用 (遠端監控)
```

## 主要功能

- **身份辨識**：AS608 指紋辨識模組
- **生理監測**：MAX30102 心率血氧感測器
- **溫度監控**：GY-906 非接觸式溫度感測器
- **智慧控制**：四路繼電器模組（電磁鎖控制）
- **數據通訊**：Native USB 串口通訊（115200 baud）

## 專案結構

```
大手攜小手_code/
├── Bmduino/              # BMduino 硬體程式
│   ├── code/            # 各感測器獨立程式
│   ├── program/         # 整合主程式
│   └── reference/       # 參考資料
├── raspberrypi/         # 樹莓派端程式
│   ├── code/            # 核心功能模組（串口通訊、數據庫、CV檢測等）
│   ├── program/         # 主程式（UI、API服務器、狀態機）
│   ├── data/            # 配置文件和數據庫
│   └── reference/       # 參考資料
└── reference/           # 專案參考文件
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
- pyserial 套件

### 安裝步驟

1. 上傳 `Bmduino/program/BMduino_Integrated.ino` 至 BMduino
2. 連接 BMduino 的 Native USB 至樹莓派或電腦
3. 安裝 Python 依賴：`pip install pyserial`
4. 執行測試腳本：`python Bmduino/program/test_bmduino.py`

## 通訊協議

詳細通訊協議請參考：[通訊協議文檔](Bmduino/program/通訊協議.md)

## 文件說明

- [BMduino 整合程式說明](Bmduino/program/README.md)
- [通訊協議詳細說明](Bmduino/program/通訊協議.md)
- [測試腳本使用說明](Bmduino/program/README_測試.md)
- [開發規範](CONTRIBUTING.md)

## 授權

本專案為「大手拉小手」競賽參賽作品。

## 聯絡資訊

如有問題或建議，歡迎提出 Issue 或 Pull Request。

