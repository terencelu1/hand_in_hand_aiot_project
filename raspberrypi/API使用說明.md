# API 使用說明

本文檔說明如何使用樹莓派智慧藥盒系統提供的 REST API。

## 基礎資訊

- **API 基礎 URL**: `http://樹莓派IP:5000`
- **協議**: HTTP/HTTPS
- **數據格式**: JSON
- **字符編碼**: UTF-8

## API 端點列表

### 1. 健康檢查

檢查 API 服務器是否正常運行。

**端點**: `GET /api/health`

**請求範例**:
```bash
curl http://192.168.1.100:5000/api/health
```

**回應範例**:
```json
{
  "success": true,
  "message": "API服務正常運行"
}
```

---

### 2. 獲取系統狀態

獲取當前系統運行狀態。

**端點**: `GET /api/status`

**請求範例**:
```bash
curl http://192.168.1.100:5000/api/status
```

**回應範例**:
```json
{
  "success": true,
  "status": {
    "mode": "standby",
    "data": {
      "object_temp": 25.3,
      "ambient_temp": 24.5,
      "heart_rate": null,
      "spo2": null
    }
  }
}
```

**狀態模式說明**:
- `standby`: 待機模式
- `working`: 工作模式（正在測量）
- `working_final`: 工作模式完成

---

### 3. 獲取使用者列表

獲取所有已註冊的使用者資訊。

**端點**: `GET /api/users`

**請求範例**:
```bash
curl http://192.168.1.100:5000/api/users
```

**回應範例**:
```json
{
  "success": true,
  "data": {
    "1": {
      "name": "使用者1號",
      "relay": 1
    },
    "2": {
      "name": "使用者2號",
      "relay": 2
    },
    "3": {
      "name": "使用者3號",
      "relay": 3
    },
    "4": {
      "name": "使用者4號",
      "relay": 4
    }
  }
}
```

---

### 4. 獲取當前感測器數據

獲取待機模式下的當前感測器數據（溫度等）。

**端點**: `GET /api/current_data`

**請求範例**:
```bash
curl http://192.168.1.100:5000/api/current_data
```

**回應範例**:
```json
{
  "success": true,
  "data": {
    "object_temp": 25.3,
    "ambient_temp": 24.5,
    "heart_rate": null,
    "spo2": null
  }
}
```

**注意**: 此端點僅在待機模式下返回數據。如果系統正在工作模式，會返回 `null`。

---

### 5. 獲取最新測量數據

獲取指定使用者的最新一次測量記錄。

**端點**: `GET /api/latest`

**請求參數**:
- `user_id` (必填): 使用者ID（整數）

**請求範例**:
```bash
curl "http://192.168.1.100:5000/api/latest?user_id=1"
```

**回應範例**:
```json
{
  "success": true,
  "data": {
    "id": 14,
    "timestamp": "2025-11-18T15:09:45.915121",
    "timestamp_readable": "2025年11月18日 15:09:45",
    "date": "2025-11-18",
    "time": "15:09:45",
    "user_id": 1,
    "user_name": "使用者1號",
    "object_temp": 24.95,
    "ambient_temp": 24.59,
    "heart_rate": 120,
    "spo2": 91
  }
}
```

**無數據時回應**:
```json
{
  "success": true,
  "data": null,
  "message": "暫無數據"
}
```

---

### 6. 獲取歷史數據

獲取指定使用者的歷史測量記錄。

**端點**: `GET /api/history`

**請求參數**:
- `user_id` (必填): 使用者ID（整數）
- `limit` (選填): 返回記錄數量限制（預設：100，最大值建議不超過1000）

**請求範例**:
```bash
# 獲取使用者1的最新50筆記錄
curl "http://192.168.1.100:5000/api/history?user_id=1&limit=50"
```

**回應範例**:
```json
{
  "success": true,
  "count": 14,
  "data": [
    {
      "id": 14,
      "timestamp": "2025-11-18T15:09:45.915121",
      "timestamp_readable": "2025年11月18日 15:09:45",
      "date": "2025-11-18",
      "time": "15:09:45",
      "user_id": 1,
      "user_name": "使用者1號",
      "object_temp": 24.95,
      "ambient_temp": 24.59,
      "heart_rate": 120,
      "spo2": 91
    },
    {
      "id": 13,
      "timestamp": "2025-11-18T15:07:42.834885",
      "timestamp_readable": "2025年11月18日 15:07:42",
      "date": "2025-11-18",
      "time": "15:07:42",
      "user_id": 1,
      "user_name": "使用者1號",
      "object_temp": 25.07,
      "ambient_temp": 24.55,
      "heart_rate": 120,
      "spo2": 97
    }
    // ... 更多記錄
  ]
}
```

**數據字段說明**:
- `id`: 記錄唯一ID
- `timestamp`: ISO格式時間戳（用於程序處理）
- `timestamp_readable`: 易讀的時間格式（用於顯示）
- `date`: 日期（YYYY-MM-DD格式）
- `time`: 時間（HH:MM:SS格式）
- `user_id`: 使用者ID
- `user_name`: 使用者名稱
- `object_temp`: 物體溫度（攝氏度）
- `ambient_temp`: 環境溫度（攝氏度）
- `heart_rate`: 心率（bpm，每分鐘心跳數）
- `spo2`: 血氧飽和度（百分比）

---

## 錯誤處理

所有 API 端點在發生錯誤時會返回以下格式：

```json
{
  "success": false,
  "error": "錯誤訊息描述"
}
```

**常見錯誤**:
- `數據庫未初始化`: 數據庫連接失敗
- `使用者映射未初始化`: 使用者配置未載入
- `當前不在待機模式或無數據`: 待機模式下無數據

**HTTP 狀態碼**:
- `200`: 請求成功
- `500`: 服務器內部錯誤

---

## 使用範例

### Python 範例

```python
import requests

# API 基礎 URL
BASE_URL = "http://192.168.1.100:5000"

# 1. 健康檢查
response = requests.get(f"{BASE_URL}/api/health")
print(response.json())

# 2. 獲取使用者列表
response = requests.get(f"{BASE_URL}/api/users")
users = response.json()["data"]
print(users)

# 3. 獲取使用者1的最新數據
response = requests.get(f"{BASE_URL}/api/latest", params={"user_id": 1})
latest_data = response.json()["data"]
if latest_data:
    print(f"最新測量時間: {latest_data['timestamp_readable']}")
    print(f"心率: {latest_data['heart_rate']} bpm")
    print(f"血氧: {latest_data['spo2']} %")

# 4. 獲取使用者1的歷史數據（最近20筆）
response = requests.get(
    f"{BASE_URL}/api/history",
    params={"user_id": 1, "limit": 20}
)
history = response.json()["data"]
for record in history:
    print(f"{record['timestamp_readable']}: 心率 {record['heart_rate']}, 血氧 {record['spo2']}")
```

### JavaScript (Fetch API) 範例

```javascript
const BASE_URL = "http://192.168.1.100:5000";

// 1. 健康檢查
fetch(`${BASE_URL}/api/health`)
  .then(response => response.json())
  .then(data => console.log(data));

// 2. 獲取使用者列表
fetch(`${BASE_URL}/api/users`)
  .then(response => response.json())
  .then(data => {
    console.log("使用者列表:", data.data);
  });

// 3. 獲取使用者1的最新數據
fetch(`${BASE_URL}/api/latest?user_id=1`)
  .then(response => response.json())
  .then(data => {
    if (data.data) {
      console.log(`最新測量: ${data.data.timestamp_readable}`);
      console.log(`心率: ${data.data.heart_rate} bpm`);
      console.log(`血氧: ${data.data.spo2} %`);
    }
  });

// 4. 獲取使用者1的歷史數據
fetch(`${BASE_URL}/api/history?user_id=1&limit=20`)
  .then(response => response.json())
  .then(data => {
    data.data.forEach(record => {
      console.log(`${record.timestamp_readable}: 心率 ${record.heart_rate}, 血氧 ${record.spo2}`);
    });
  });
```

### Android (Kotlin) 範例

```kotlin
import okhttp3.*
import org.json.JSONObject

class ApiClient {
    private val baseUrl = "http://192.168.1.100:5000"
    private val client = OkHttpClient()
    
    // 獲取使用者列表
    fun getUsers(callback: (Map<String, User>) -> Unit) {
        val request = Request.Builder()
            .url("$baseUrl/api/users")
            .build()
        
        client.newCall(request).enqueue(object : Callback {
            override fun onResponse(call: Call, response: Response) {
                val json = JSONObject(response.body?.string() ?: "")
                val usersJson = json.getJSONObject("data")
                // 解析使用者數據
                // ...
            }
            
            override fun onFailure(call: Call, e: IOException) {
                e.printStackTrace()
            }
        })
    }
    
    // 獲取最新數據
    fun getLatestData(userId: Int, callback: (Measurement?) -> Unit) {
        val request = Request.Builder()
            .url("$baseUrl/api/latest?user_id=$userId")
            .build()
        
        client.newCall(request).enqueue(object : Callback {
            override fun onResponse(call: Call, response: Response) {
                val json = JSONObject(response.body?.string() ?: "")
                val data = json.optJSONObject("data")
                // 解析測量數據
                // ...
            }
            
            override fun onFailure(call: Call, e: IOException) {
                e.printStackTrace()
            }
        })
    }
}
```

---

## 注意事項

1. **網路連接**: 確保手機/電腦與樹莓派在同一個 Wi-Fi 網絡中
2. **防火牆**: 確保樹莓派的 5000 端口未被防火牆阻擋
3. **IP 地址**: 樹莓派的 IP 地址可能會變動，建議使用固定 IP 或 DHCP 保留
4. **數據更新**: 歷史數據會隨著新的測量而增加，建議定期清理舊數據
5. **並發請求**: API 服務器支持多個並發請求，但建議控制請求頻率，避免過載

---

## 測試工具

專案提供了測試腳本 `test_api.py`，可以用來測試所有 API 端點：

```bash
# 使用預設 IP (192.168.1.100)
python3 raspberrypi/test_api.py

# 指定樹莓派 IP
python3 raspberrypi/test_api.py 192.168.1.101
```

---

## 更新日誌

- **2025-11-18**: 初始版本，包含所有基礎 API 端點
- 添加了易讀的時間格式和使用者名稱字段

---

最後更新：2025-11-18

