# 測試程式說明

## 服藥動作檢測測試

### 測試程式位置
`code/test_medication_detector.py`

### 使用方法

1. **安裝依賴**（如果還沒安裝）：
   ```bash
   pip3 install opencv-python mediapipe
   ```

2. **運行測試程式**：
   ```bash
   cd raspberrypi
   python3 code/test_medication_detector.py
   ```

3. **測試步驟**：
   - 程式會開啟攝影機視窗
   - 將手部靠近畫面中央偏下的區域（綠色圓圈標示的嘴部區域）
   - 保持1-2秒，程式會檢測到服藥動作
   - 按 'q' 鍵退出

### 參數調整

如果需要調整檢測靈敏度，可以修改 `test_medication_detector.py` 中的參數：

```python
sensitivity = 0.7  # 靈敏度（0-1，越高越靈敏）
mouth_region_center_y = int(height * 0.55)  # 嘴部區域Y座標（0-1，0.5為中央）
mouth_region_radius = int(min(width, height) * 0.15)  # 嘴部區域半徑
```

### 故障排除

#### 無法開啟攝影機
- 檢查攝影機是否已連接
- 嘗試修改 `camera_id`（0, 1, 2 等）
- 在Linux上檢查權限：`sudo chmod 666 /dev/video0`

#### 檢測不到手部
- 確保光線充足
- 手部要清晰可見
- 嘗試降低 `min_detection_confidence` 參數

#### 檢測太敏感或太不敏感
- 調整 `sensitivity` 參數
- 調整 `required_frames`（需要連續檢測到的幀數）
- 調整 `mouth_region_radius`（嘴部區域大小）

