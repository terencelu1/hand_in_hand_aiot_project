<!--
Sync Impact Report:
- Version change: 1.1.0 → 1.2.0
- Added sections:
  - VIII. 組件間通訊 (Inter-Component Communication)
- Removed sections: None
- Templates requiring updates:
  - ✅ updated: .specify/templates/plan-template.md
  - ✅ updated: .specify/templates/spec-template.md
- Follow-up TODOs: None
-->
# 智慧藥盒系統 Constitution

## Core Principles

### I. 硬體整合與感測 (Hardware Integration & Sensing)
系統必須使用 Bmduino (BM53A367A) 進行可靠的感測器數據採集和致動器控制（四路電磁鎖）。具體的感測器規格如下：
- **指紋辨識**: AS608 (透過 UART 介面)
- **血氧心律**: MAX30102 (透過 I2C 介面)
- **環境溫濕度**: DHT11
- **非接觸式體溫 (可選)**: GY-906 (透過 I2C 介面)
這確保了系統物理互動部分的穩健性、可靠性與規格的明確性。

### II. 中心化數據中樞 (Centralized Data Hub)
樹莓派必須作為中心伺服器，負責從 Bmduino 收集數據、儲存數據，並透過穩定的 API 將其提供給行動應用程式。此設計旨在建立一個單一且權威的數據來源。

### III. 清晰的使用者指引 (Clear User Guidance)
系統必須在樹莓派上提供一個清晰、直觀的使用者介面（UI），以引導患者完成服藥和健康監測的每一步驟。這對確保使用者的遵從性和操作安全性至關重要。

### IV. 動作驗證與電腦視覺 (Action Verification & Computer Vision)
系統必須使用電腦視覺技術（例如 MediaPipe）來驗證關鍵的患者動作，特別是服藥行為。這增加了一層安全性，確保核心流程被正確遵循。

### V. 遠端可及性 (Remote Accessibility)
系統必須允許護理人員或使用者透過行動應用程式進行遠端監控。該應用程式將從樹莓派伺服器檢索歷史數據（心率、血氧）和即時狀態（藥品環境、藥盒歸位狀態），提供全面的系統可視性。

### VI. 標準化目錄結構 (Standardized Directory Structure)
在 `Bmduino` 和 `raspberrypi` 模組中的所有開發都必須遵守指定的目錄結構：
- `code/`: 用於存放獨立的小功能或腳本。
- `data/`: 用於存放數據庫、數據集或數據生成腳本。
- `program/`: 用於存放整合性的完整功能程式。
- `reference/`: 用於存放相關的參考文件與手冊。
- `report/`: 用於存放專案報告與分析。
此規範確保了程式碼的一致性、可維護性和可讀性。

### VII. 開發環境與工具鏈 (Development Environment & Toolchain)
Bmduino 的韌體開發必須使用 Arduino IDE，並以 .ino 專案檔案的形式提供。這確保了開發環境的一致性和程式碼的可維護性。

### VIII. 組件間通訊 (Inter-Component Communication)
Bmduino 與樹莓派之間必須透過有線方式連接進行雙向通訊。Bmduino 負責將感測器數據上傳至樹莓派，而樹莓派則傳送指令（例如，開啟指定的電磁鎖）給 Bmduino 進行硬體控制。此原則確保了兩個核心組件之間的穩定與即時互動。

## Governance
此憲法文件是專案開發的最高準則，所有開發活動均需遵守。任何修訂都必須經過正式的審查流程，並記錄版本變更。

**Version**: 1.2.0 | **Ratified**: 2025-11-10 | **Last Amended**: 2025-11-10