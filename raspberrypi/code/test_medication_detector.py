#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
服藥動作檢測測試程式
用於測試電腦視覺檢測功能
"""

import cv2
import mediapipe as mp
import time
import sys
import numpy as np

# MediaPipe初始化 - 手部檢測
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(
    static_image_mode=False,
    max_num_hands=2,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

# MediaPipe初始化 - 臉部網格（用於檢測嘴巴）
mp_face_mesh = mp.solutions.face_mesh
face_mesh = mp_face_mesh.FaceMesh(
    static_image_mode=False,
    max_num_faces=1,
    refine_landmarks=True,  # 啟用精細化標記點（包含嘴巴內部點）
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

mp_drawing = mp.solutions.drawing_utils
mp_drawing_styles = mp.solutions.drawing_styles

# 嘴巴關鍵點索引（MediaPipe Face Mesh）
# 外嘴唇輪廓點
MOUTH_OUTER_INDICES = [61, 146, 91, 181, 84, 17, 314, 405, 320, 307, 375, 321, 308, 324, 318]
# 內嘴唇點
MOUTH_INNER_INDICES = [78, 95, 88, 178, 87, 14, 317, 402, 318, 324]
# 嘴巴中心點（大約）
MOUTH_CENTER_INDEX = 13  # 上唇中心

# 攝影機設定
camera_id = 0
width = 640
height = 480

# 嘴部區域設定（動態檢測，如果檢測不到臉部則使用預設值）
mouth_center_x = width // 2
mouth_center_y = int(height * 0.55)
mouth_radius = int(min(width, height) * 0.12)  # 嘴部區域半徑（稍微小一點，更精確）
face_detected = False

# 檢測參數
sensitivity = 0.7
required_frames = int(10 * sensitivity)  # 需要連續檢測到的幀數
hand_near_mouth_count = 0

print("=" * 50)
print("服藥動作檢測測試程式（支援嘴巴檢測）")
print("=" * 50)
print(f"攝影機ID: {camera_id}")
print(f"解析度: {width}x{height}")
print(f"靈敏度: {sensitivity}, 需要連續幀數: {required_frames}")
print("=" * 50)
print("操作說明:")
print("- 面向攝影機，確保臉部清晰可見")
print("- 程式會自動檢測您的嘴巴位置")
print("- 將手部靠近嘴巴區域")
print("- 保持1-2秒即可觸發檢測")
print("- 按 'q' 鍵退出")
print("=" * 50)

# 開啟攝影機
cap = cv2.VideoCapture(camera_id)
if not cap.isOpened():
    print(f"錯誤: 無法開啟攝影機 {camera_id}")
    print("請檢查:")
    print("1. 攝影機是否已連接")
    print("2. 攝影機ID是否正確（可用 0, 1, 2 等嘗試）")
    sys.exit(1)

cap.set(cv2.CAP_PROP_FRAME_WIDTH, width)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, height)

print("\n攝影機已開啟，開始檢測...\n")

detected = False
frame_count = 0

def get_mouth_position(face_landmarks, frame_width, frame_height):
    """
    從臉部標記點中獲取嘴巴位置
    
    Args:
        face_landmarks: MediaPipe臉部標記點
        frame_width: 畫面寬度
        frame_height: 畫面高度
    
    Returns:
        (mouth_center_x, mouth_center_y, mouth_radius) 或 None
    """
    try:
        # 獲取嘴巴外圍關鍵點
        mouth_points = []
        for idx in MOUTH_OUTER_INDICES:
            if idx < len(face_landmarks.landmark):
                landmark = face_landmarks.landmark[idx]
                x = int(landmark.x * frame_width)
                y = int(landmark.y * frame_height)
                mouth_points.append((x, y))
        
        if len(mouth_points) < 3:
            return None
        
        # 計算嘴巴中心點
        mouth_center_x = int(np.mean([p[0] for p in mouth_points]))
        mouth_center_y = int(np.mean([p[1] for p in mouth_points]))
        
        # 計算嘴巴半徑（最大距離）
        max_distance = 0
        for x, y in mouth_points:
            distance = np.sqrt((x - mouth_center_x)**2 + (y - mouth_center_y)**2)
            max_distance = max(max_distance, distance)
        
        # 稍微放大一點，增加檢測範圍
        mouth_radius = int(max_distance * 1.5)
        
        return (mouth_center_x, mouth_center_y, mouth_radius)
    except Exception as e:
        return None

try:
    while True:
        ret, frame = cap.read()
        if not ret:
            print("警告: 無法讀取攝影機畫面")
            time.sleep(0.1)
            continue
        
        frame_count += 1
        
        # 水平翻轉（鏡像效果）
        frame = cv2.flip(frame, 1)
        
        # 創建顯示畫面（圓形點陣圖效果）
        # 創建白色背景
        display_frame = np.ones((height, width, 3), dtype=np.uint8) * 200  # 淡灰色背景
        
        # 點陣參數
        dot_size = 3  # 點的大小（更密集）
        dot_spacing = 4  # 點之間的間距（更小=更密集）
        
        # 轉換為灰度
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        
        # 調整為白灰色調
        gray = cv2.convertScaleAbs(gray, alpha=0.6, beta=100)
        
        # 在網格上繪製圓形點
        for y in range(0, height, dot_spacing):
            for x in range(0, width, dot_spacing):
                # 獲取對應位置的灰度值
                if y < gray.shape[0] and x < gray.shape[1]:
                    intensity = int(gray[y, x])
                    # 將灰度值映射到點的大小和顏色
                    # 較暗的區域點更大更明顯
                    dot_radius = max(1, int(dot_size * (255 - intensity) / 255))
                    dot_color = int(intensity * 0.8)  # 稍微調暗
                    
                    # 繪製圓形點
                    cv2.circle(display_frame, (x, y), dot_radius, 
                             (dot_color, dot_color, dot_color), -1)
        
        # 應用輕微模糊，讓點陣更柔和（kernel size 必須是奇數）
        display_frame = cv2.GaussianBlur(display_frame, (3, 3), 0)
        
        # 轉換為RGB（用於MediaPipe）
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        
        # 檢測臉部（獲取嘴巴位置）
        face_results = face_mesh.process(rgb_frame)
        current_mouth_x = mouth_center_x
        current_mouth_y = mouth_center_y
        current_mouth_radius = mouth_radius
        face_detected = False
        
        if face_results.multi_face_landmarks:
            for face_landmarks in face_results.multi_face_landmarks:
                # 繪製臉部網格（可選，用於調試）
                # mp_drawing.draw_landmarks(
                #     frame, face_landmarks, mp_face_mesh.FACEMESH_CONTOURS,
                #     None, mp_drawing_styles.get_default_face_mesh_contours_style()
                # )
                
                # 獲取嘴巴位置
                mouth_pos = get_mouth_position(face_landmarks, width, height)
                if mouth_pos:
                    current_mouth_x, current_mouth_y, current_mouth_radius = mouth_pos
                    face_detected = True
                    
                    # 不繪製嘴巴關鍵點（保持點陣圖效果）
                    pass
        
        # 檢測手部
        hand_results = hands.process(rgb_frame)
        
        hand_detected_near_mouth = False
        hand_landmarks_list = []
        min_distance = float('inf')
        
        if hand_results.multi_hand_landmarks:
            for hand_landmarks in hand_results.multi_hand_landmarks:
                # 不繪製手部關鍵點（保持點陣圖效果）
                pass
                
                # 獲取手腕位置（landmark 0）
                wrist = hand_landmarks.landmark[0]
                wrist_x = int(wrist.x * width)
                wrist_y = int(wrist.y * height)
                
                # 獲取食指指尖位置（landmark 8）
                index_tip = hand_landmarks.landmark[8]
                index_x = int(index_tip.x * width)
                index_y = int(index_tip.y * height)
                
                # 計算手部關鍵點到嘴巴的距離（使用較近的點）
                distance_wrist = np.sqrt((wrist_x - current_mouth_x)**2 + 
                                        (wrist_y - current_mouth_y)**2)
                distance_index = np.sqrt((index_x - current_mouth_x)**2 + 
                                        (index_y - current_mouth_y)**2)
                distance_to_mouth = min(distance_wrist, distance_index)
                min_distance = min(min_distance, distance_to_mouth)
                
                hand_landmarks_list.append({
                    'wrist': (wrist_x, wrist_y),
                    'index_tip': (index_x, index_y),
                    'distance': distance_to_mouth
                })
                
                # 檢查是否接近嘴巴
                if distance_to_mouth < current_mouth_radius:
                    hand_detected_near_mouth = True
        
        # 累計檢測結果
        if hand_detected_near_mouth:
            hand_near_mouth_count += 1
            if hand_near_mouth_count >= required_frames and not detected:
                # 檢測到服藥動作
                detected = True
                print(f"\n✓ 檢測到服藥動作！ (第 {frame_count} 幀)")
                print(f"  手部在嘴部區域停留了 {hand_near_mouth_count} 幀")
        else:
            if hand_near_mouth_count > 0:
                hand_near_mouth_count = 0
                if detected:
                    print("  手部已移開嘴部區域")
                    detected = False
        
        # 不繪製任何標記（保持純點陣圖效果）
        
        # 在畫面下方直接顯示狀態文字（黑色字）
        status_y = height - 30  # 距離底部30像素
        
        # 只顯示偵測狀態（英文）
        if detected:
            status_text = "Detected"
        else:
            status_text = "Not Detected"
        
        # 在畫面上直接繪製黑色文字
        cv2.putText(display_frame, status_text, (10, status_y),
                   cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 0, 0), 3)  # 黑色粗體文字
        
        final_frame = display_frame
        
        # 顯示畫面
        cv2.imshow('Medication Detection Test', final_frame)
        
        # 按 'q' 退出
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

except KeyboardInterrupt:
    print("\n\n收到中斷信號，正在退出...")

finally:
    cap.release()
    cv2.destroyAllWindows()
    print("\n測試結束")

