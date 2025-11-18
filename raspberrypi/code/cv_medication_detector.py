#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
電腦視覺服藥動作辨識模組
使用MediaPipe檢測手部接近嘴部的動作
"""

import cv2
import mediapipe as mp
import threading
import time
import numpy as np
from typing import Optional, Callable
import logging

logger = logging.getLogger(__name__)


class MedicationDetector:
    """服藥動作辨識類別"""
    
    def __init__(self, camera_id: int = 0, width: int = 640, height: int = 480,
                 sensitivity: float = 0.7, timeout: int = 30):
        """
        初始化服藥動作辨識
        
        Args:
            camera_id: 攝影機ID
            width: 影像寬度
            height: 影像高度
            sensitivity: 檢測靈敏度（0-1，越高越靈敏）
            timeout: 超時時間（秒）
        """
        self.camera_id = camera_id
        self.width = width
        self.height = height
        self.sensitivity = sensitivity
        self.timeout = timeout
        
        # MediaPipe初始化 - 手部檢測
        self.mp_hands = mp.solutions.hands
        self.hands = self.mp_hands.Hands(
            static_image_mode=False,
            max_num_hands=2,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )
        
        # MediaPipe初始化 - 臉部網格（用於檢測嘴巴）
        self.mp_face_mesh = mp.solutions.face_mesh
        self.face_mesh = self.mp_face_mesh.FaceMesh(
            static_image_mode=False,
            max_num_faces=1,
            refine_landmarks=True,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )
        
        self.mp_drawing = mp.solutions.drawing_utils
        
        # 嘴巴關鍵點索引
        self.MOUTH_OUTER_INDICES = [61, 146, 91, 181, 84, 17, 314, 405, 320, 307, 375, 321, 308, 324, 318]
        
        # 狀態
        self.cap: Optional[cv2.VideoCapture] = None
        self.detecting = False
        self.detection_thread: Optional[threading.Thread] = None
        self.detected = False
        
        # 回調函數
        self.on_detected: Optional[Callable] = None
        self.on_timeout: Optional[Callable] = None
        
        # 嘴部區域（動態檢測，如果檢測不到臉部則使用預設值）
        self.mouth_region_center_x = width // 2
        self.mouth_region_center_y = int(height * 0.55)
        self.mouth_region_radius = int(min(width, height) * 0.12)
    
    def start_detection(self, on_detected: Optional[Callable] = None,
                       on_timeout: Optional[Callable] = None) -> bool:
        """
        開始檢測
        
        Args:
            on_detected: 檢測到動作時的回調函數
            on_timeout: 超時時的回調函數
        
        Returns:
            是否成功啟動
        """
        if self.detecting:
            logger.warning("檢測已在進行中")
            return False
        
        try:
            self.cap = cv2.VideoCapture(self.camera_id)
            if not self.cap.isOpened():
                logger.error(f"無法開啟攝影機: {self.camera_id}")
                return False
            
            self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, self.width)
            self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, self.height)
            
            self.on_detected = on_detected
            self.on_timeout = on_timeout
            self.detected = False
            self.detecting = True
            
            # 啟動檢測線程
            self.detection_thread = threading.Thread(target=self._detection_loop, daemon=True)
            self.detection_thread.start()
            
            logger.info("開始服藥動作檢測")
            return True
            
        except Exception as e:
            logger.error(f"啟動檢測失敗: {e}")
            return False
    
    def stop_detection(self):
        """停止檢測"""
        self.detecting = False
        if self.detection_thread:
            self.detection_thread.join(timeout=2)
        
        if self.cap:
            self.cap.release()
            self.cap = None
        
        logger.info("停止服藥動作檢測")
    
    def _detection_loop(self):
        """檢測迴圈（在獨立線程中運行）"""
        start_time = time.time()
        hand_near_mouth_count = 0
        required_frames = int(10 * self.sensitivity)  # 需要連續檢測到的幀數
        
        # 用於存儲當前畫面（供UI顯示）
        self.current_frame = None
        self.frame_lock = threading.Lock()
        
        try:
            while self.detecting:
                # 檢查超時
                if time.time() - start_time > self.timeout:
                    logger.info("檢測超時")
                    if self.on_timeout:
                        try:
                            self.on_timeout()
                        except Exception as e:
                            logger.error(f"超時回調錯誤: {e}")
                    break
                
                ret, frame = self.cap.read()
                if not ret:
                    logger.warning("無法讀取攝影機畫面")
                    time.sleep(0.1)
                    continue
                
                # 水平翻轉（鏡像效果，更符合使用者視角）
                frame = cv2.flip(frame, 1)
                
                # 轉換為RGB
                rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                
                # 檢測臉部（獲取嘴巴位置）
                face_results = self.face_mesh.process(rgb_frame)
                current_mouth_x = self.mouth_region_center_x
                current_mouth_y = self.mouth_region_center_y
                current_mouth_radius = self.mouth_region_radius
                
                if face_results.multi_face_landmarks:
                    for face_landmarks in face_results.multi_face_landmarks:
                        mouth_pos = self._get_mouth_position(face_landmarks, self.width, self.height)
                        if mouth_pos:
                            current_mouth_x, current_mouth_y, current_mouth_radius = mouth_pos
                            break
                
                # 檢測手部
                hand_results = self.hands.process(rgb_frame)
                
                hand_detected_near_mouth = False
                
                if hand_results.multi_hand_landmarks:
                    for hand_landmarks in hand_results.multi_hand_landmarks:
                        # 獲取手腕位置（landmark 0）
                        wrist = hand_landmarks.landmark[0]
                        wrist_x = int(wrist.x * self.width)
                        wrist_y = int(wrist.y * self.height)
                        
                        # 獲取食指指尖位置（landmark 8）
                        index_tip = hand_landmarks.landmark[8]
                        index_x = int(index_tip.x * self.width)
                        index_y = int(index_tip.y * self.height)
                        
                        # 計算手部關鍵點到嘴巴的距離（使用較近的點）
                        distance_wrist = np.sqrt((wrist_x - current_mouth_x)**2 + 
                                                (wrist_y - current_mouth_y)**2)
                        distance_index = np.sqrt((index_x - current_mouth_x)**2 + 
                                                (index_y - current_mouth_y)**2)
                        distance_to_mouth = min(distance_wrist, distance_index)
                        
                        # 檢查是否接近嘴部
                        if distance_to_mouth < current_mouth_radius:
                            hand_detected_near_mouth = True
                            break
                
                # 累計檢測結果
                if hand_detected_near_mouth:
                    hand_near_mouth_count += 1
                    if hand_near_mouth_count >= required_frames:
                        # 檢測到服藥動作
                        logger.info("檢測到服藥動作")
                        self.detected = True
                        if self.on_detected:
                            try:
                                self.on_detected()
                            except Exception as e:
                                logger.error(f"檢測回調錯誤: {e}")
                        break
                else:
                    hand_near_mouth_count = 0
                
                # 處理點陣圖效果並保存當前畫面
                processed_frame = self._apply_dot_matrix_effect(frame)
                # 在畫面下方添加狀態文字
                status_text = "Detected" if self.detected else "Not Detected"
                cv2.putText(processed_frame, status_text, (10, processed_frame.shape[0] - 30),
                           cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 0, 0), 3)
                with self.frame_lock:
                    self.current_frame = processed_frame
                
                time.sleep(0.1)  # 約10fps，降低CPU使用率
        
        except Exception as e:
            logger.error(f"檢測迴圈錯誤: {e}")
        finally:
            self.detecting = False
            if self.cap:
                self.cap.release()
                self.cap = None
    
    def _get_mouth_position(self, face_landmarks, frame_width, frame_height):
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
            for idx in self.MOUTH_OUTER_INDICES:
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
            logger.warning(f"獲取嘴巴位置失敗: {e}")
            return None
    
    def _apply_dot_matrix_effect(self, frame):
        """
        應用圓形點陣圖效果
        
        Args:
            frame: 原始畫面
        
        Returns:
            處理後的畫面
        """
        height, width = frame.shape[:2]
        
        # 創建淡灰色背景
        display_frame = np.ones((height, width, 3), dtype=np.uint8) * 200
        
        # 點陣參數
        dot_size = 3
        dot_spacing = 4
        
        # 轉換為灰度
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        
        # 調整為白灰色調
        gray = cv2.convertScaleAbs(gray, alpha=0.6, beta=100)
        
        # 在網格上繪製圓形點
        for y in range(0, height, dot_spacing):
            for x in range(0, width, dot_spacing):
                if y < gray.shape[0] and x < gray.shape[1]:
                    intensity = int(gray[y, x])
                    dot_radius = max(1, int(dot_size * (255 - intensity) / 255))
                    dot_color = int(intensity * 0.8)
                    
                    # 繪製圓形點
                    cv2.circle(display_frame, (x, y), dot_radius,
                             (dot_color, dot_color, dot_color), -1)
        
        # 應用輕微模糊
        display_frame = cv2.GaussianBlur(display_frame, (3, 3), 0)
        
        return display_frame
    
    def get_current_frame(self):
        """
        獲取當前處理後的畫面（用於UI顯示）
        
        Returns:
            當前畫面或None
        """
        with self.frame_lock:
            return self.current_frame.copy() if self.current_frame is not None else None
    
    def is_detecting(self) -> bool:
        """檢查是否正在檢測"""
        return self.detecting
    
    def has_detected(self) -> bool:
        """檢查是否已檢測到動作"""
        return self.detected

