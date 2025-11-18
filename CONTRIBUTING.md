# 開發規範

本文檔定義了「大手拉小手 - 智慧藥盒健康監測系統」專案的開發規範，所有貢獻者都應遵循這些規範。

## 目錄

- [Git 提交規範](#git-提交規範)
- [代碼規範](#代碼規範)
- [文件命名規範](#文件命名規範)
- [目錄結構規範](#目錄結構規範)
- [開發流程](#開發流程)

---

## Git 提交規範

### 提交訊息格式

提交訊息應遵循以下格式：

```
<類型>(<範圍>): <主題>

<詳細說明>

<相關 Issue>
```

### 提交類型

- `feat`: 新功能
- `fix`: 修復錯誤
- `docs`: 文檔更新
- `style`: 代碼格式調整（不影響功能）
- `refactor`: 重構代碼
- `test`: 測試相關
- `chore`: 構建過程或輔助工具的變動

### 提交範圍

- `bmduino`: BMduino 相關代碼
- `raspberrypi`: 樹莓派相關代碼
- `docs`: 文檔
- `config`: 配置文件

### 範例

```
feat(bmduino): 新增指紋辨識功能

- 整合 AS608 指紋辨識模組
- 實現指紋註冊和驗證功能
- 添加錯誤處理機制

Closes #123
```

```
fix(bmduino): 修復 MAX30102 數據讀取異常

修正心率血氧感測器在待機模式下的數據讀取問題
```

```
docs: 更新通訊協議文檔

補充工作模式的詳細說明和錯誤處理流程
```

### 分支命名規範

- `main`: 主分支，穩定版本
- `develop`: 開發分支
- `feature/<功能名稱>`: 功能分支
- `fix/<問題描述>`: 修復分支
- `docs/<文檔類型>`: 文檔分支

### 提交頻率

- 每個功能或修復完成後立即提交
- 避免累積大量變更後一次性提交
- 每次提交應為一個完整的邏輯單元

---

## 代碼規範

### Arduino 代碼規範

#### 命名規範

- **變數**: 使用 `camelCase`，例如：`heartRate`, `objectTemp`
- **常數**: 使用 `UPPER_SNAKE_CASE`，例如：`WORK_MODE_TIMEOUT`, `MAX_NO_FINGER_COUNT`
- **函數**: 使用 `camelCase`，例如：`handleStandbyMode()`, `initMAX30102()`
- **類別**: 使用 `PascalCase`，例如：`MAX30105`, `MLX90614`

#### 代碼風格

```cpp
// 好的範例
void handleStandbyMode() {
  unsigned long currentTime = millis();
  
  if (currentTime - lastStandbyReport >= STANDBY_REPORT_INTERVAL) {
    lastStandbyReport = currentTime;
    // 處理邏輯
  }
}

// 避免的寫法
void handleStandbyMode(){
unsigned long currentTime=millis();
if(currentTime-lastStandbyReport>=STANDBY_REPORT_INTERVAL){
```

#### 註釋規範

- 文件開頭應包含文件說明
- 複雜邏輯必須添加註釋
- 函數應有功能說明

```cpp
/***************************************************
  BMduino 整合程式 - 三模式系統
  
  模式說明：
  1. 待機模式：持續感測 GY906、指紋辨識、心律血氧，回報狀態
  2. 工作模式：指紋觸發後，測量心律血氧，數據穩定後回報
  3. 接收模式：接收樹莓派命令，控制繼電器
  ****************************************************/

/**
 * 處理待機模式
 * 持續監控感測器並每1秒回報一次數據
 */
void handleStandbyMode() {
  // 實現邏輯
}
```

### Python 代碼規範

#### 命名規範

- **變數和函數**: 使用 `snake_case`，例如：`heart_rate`, `object_temp`
- **類別**: 使用 `PascalCase`，例如：`BMduinoTester`, `BMduinoCommunicator`
- **常數**: 使用 `UPPER_SNAKE_CASE`，例如：`DEFAULT_BAUDRATE`, `TIMEOUT_SECONDS`

#### 代碼風格

遵循 PEP 8 規範：

```python
# 好的範例
def read_data(self):
    """讀取數據（在背景執行）"""
    while self.running:
        try:
            if self.ser and self.ser.in_waiting > 0:
                line = self.ser.readline().decode('utf-8', errors='ignore').strip()
                if line:
                    self.received_data.append(line)
        except Exception as e:
            print(f"讀取錯誤：{e}")
        time.sleep(0.01)
```

#### 文檔字符串

所有函數和類別都應包含文檔字符串：

```python
class BMduinoTester:
    """BMduino 整合程式測試腳本
    用於測試三個模式是否正常運作
    """
    
    def connect(self):
        """連接到 BMduino
        
        Returns:
            bool: 連接成功返回 True，失敗返回 False
        """
        # 實現邏輯
```

---

## 文件命名規範

### Arduino 文件

- 主程式文件：使用描述性名稱，例如：`BMduino_Integrated.ino`
- 庫文件：使用模組名稱，例如：`MAX30102.h`, `GY906.h`
- 測試文件：使用 `test_` 前綴，例如：`test_sensor.ino`

### Python 文件

- 主程式：使用描述性名稱，例如：`test_bmduino.py`
- 測試文件：使用 `test_` 前綴，例如：`test_bmduino.py`
- 工具腳本：使用描述性名稱，例如：`serial_monitor.py`

### 文檔文件

- README 文件：`README.md` 或 `README_<描述>.md`
- 規範文件：`CONTRIBUTING.md`, `CHANGELOG.md`
- 協議文檔：使用描述性名稱，例如：`通訊協議.md`

### 禁止使用的字符

- 避免使用空格，使用 `-` 或 `_` 替代
- 避免使用特殊字符：`<>:"/\|?*`
- 中文文件名應使用繁體中文

---

## 目錄結構規範

```
大手攜小手_code/
├── Bmduino/                    # BMduino 硬體程式
│   ├── code/                   # 各感測器獨立程式
│   │   ├── AS608/             # 指紋辨識模組
│   │   ├── MAX30102/          # 心率血氧感測器
│   │   ├── GY-906/            # 溫度感測器
│   │   └── 4Relay/            # 繼電器模組
│   ├── program/               # 整合主程式
│   ├── tools/                 # 工具腳本
│   ├── reference/            # 參考資料
│   └── report/                # 報告文件
├── raspberrypi/               # 樹莓派端程式
│   ├── code/                  # 核心代碼
│   ├── program/               # 主程式
│   ├── models/                # 機器學習模型
│   ├── data/                  # 數據文件
│   └── reference/             # 參考資料
├── reference/                 # 專案參考文件
├── README.md                  # 專案說明
└── CONTRIBUTING.md            # 開發規範（本文件）
```

### 目錄命名規範

- 使用小寫字母和連字符：`code`, `reference`
- 避免使用空格
- 保持目錄結構清晰和邏輯性

---

## 開發流程

### 1. 創建功能分支

```bash
git checkout -b feature/新功能名稱
# 或
git checkout -b fix/問題描述
```

### 2. 開發和測試

- 編寫代碼
- 添加必要的註釋和文檔
- 進行本地測試
- 確保代碼符合規範

### 3. 提交變更

```bash
git add .
git commit -m "feat(範圍): 提交訊息"
```

### 4. 推送到遠端

```bash
git push origin feature/新功能名稱
```

### 5. 創建 Pull Request

- 在 GitHub 上創建 Pull Request
- 填寫清晰的描述和相關 Issue
- 等待代碼審查

### 6. 合併到主分支

- 通過審查後合併到 `main` 分支
- 刪除功能分支

---

## 代碼審查規範

### 審查重點

1. **功能正確性**: 代碼是否實現預期功能
2. **代碼質量**: 是否符合規範，是否有潛在問題
3. **文檔完整性**: 是否有必要的註釋和文檔
4. **測試覆蓋**: 是否有適當的測試

### 審查意見

- 使用建設性的語言
- 提供具體的改進建議
- 對於小問題可以直接修改並標註

---

## 版本管理

### 版本號格式

遵循 [語義化版本](https://semver.org/lang/zh-TW/)：

- `MAJOR.MINOR.PATCH`
- `MAJOR`: 不兼容的 API 修改
- `MINOR`: 向下兼容的功能新增
- `PATCH`: 向下兼容的問題修復

### 標籤規範

- 使用 `v` 前綴：`v1.0.0`
- 發布版本時創建標籤
- 在 CHANGELOG.md 中記錄變更

---

## 問題報告

### Issue 標題格式

```
[類型] 簡短描述
```

類型：
- `bug`: 錯誤報告
- `feature`: 功能請求
- `docs`: 文檔問題
- `question`: 問題詢問

### Issue 內容

應包含：
- 問題描述
- 重現步驟
- 預期行為
- 實際行為
- 環境信息（硬體、軟體版本等）

---

## 聯絡方式

如有疑問或建議，請：
- 創建 Issue
- 發送 Pull Request
- 聯繫專案維護者

---

**最後更新**: 2025-01-XX

