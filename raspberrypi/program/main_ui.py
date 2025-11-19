#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
主UI應用程式
使用PyQt6實現現代化全螢幕顯示界面
"""

import sys
import cv2
import numpy as np
from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout,
                             QHBoxLayout, QLabel, QGraphicsOpacityEffect, QFrame)
from PyQt6.QtCore import Qt, QTimer, QPropertyAnimation, QEasingCurve, pyqtSignal, QObject, QSize, QRect
from PyQt6.QtGui import QFont, QColor, QPalette, QImage, QPixmap, QPainter, QPen, QBrush
from datetime import datetime
from typing import Optional, Dict, Any
import logging

# 導入狀態機
from program.state_machine import SystemState

logger = logging.getLogger(__name__)


class StepIndicator(QWidget):
    """流程步驟指示器"""
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self.steps = [
            "指紋辨識",
            "身份確認",
            "心律血氧檢測",
            "取藥確認"
        ]
        self.current_step = 0
        self.setMinimumHeight(140)  # 增加高度避免文字被切
        self.setMaximumHeight(160)
    
    def set_current_step(self, step: int):
        """設置當前步驟（0-3）"""
        self.current_step = max(0, min(step, len(self.steps) - 1))
        self.update()
    
    def paintEvent(self, event):
        """繪製步驟指示器"""
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        
        width = self.width()
        height = self.height()
        step_width = width / len(self.steps)
        
        for i, step_name in enumerate(self.steps):
            x = i * step_width + step_width / 2
            
            # 步驟圓圈
            if i < self.current_step:
                # 已完成：綠色實心圓
                color = QColor(76, 175, 80)
                painter.setBrush(QBrush(color))
                painter.setPen(QPen(color, 2))
            elif i == self.current_step:
                # 當前步驟：藍色實心圓，帶動畫效果
                color = QColor(33, 150, 243)
                painter.setBrush(QBrush(color))
                painter.setPen(QPen(color, 2))
            else:
                # 未完成：灰色空心圓
                color = QColor(200, 200, 200)
                painter.setBrush(Qt.BrushStyle.NoBrush)
                painter.setPen(QPen(color, 2))
            
            # 繪製圓圈（位置稍微上移，給文字更多空間）
            radius = 20 if i == self.current_step else 15
            circle_y = height / 2 - radius - 10  # 圓圈上移10像素
            painter.drawEllipse(int(x - radius), int(circle_y), radius * 2, radius * 2)
            
            # 繪製步驟名稱（位置在圓圈下方，確保有足夠空間）
            font = QFont("Microsoft JhengHei", 16)
            if i == self.current_step:
                font.setBold(True)
            painter.setFont(font)
            painter.setPen(QColor(100, 100, 100) if i > self.current_step else QColor(50, 50, 50))
            text_y = int(circle_y + radius * 2 + 15)  # 文字在圓圈下方15像素
            text_rect = QRect(int(x - step_width / 2), text_y, int(step_width), 60)
            painter.drawText(text_rect, Qt.AlignmentFlag.AlignCenter, step_name)
            
            # 連接線（位置對應圓圈中心）
            if i < len(self.steps) - 1:
                line_x = x + radius
                line_y = int(circle_y + radius)  # 對應圓圈中心
                line_end_x = (i + 1) * step_width + step_width / 2 - radius
                
                if i < self.current_step:
                    line_color = QColor(76, 175, 80)
                else:
                    line_color = QColor(200, 200, 200)
                
                painter.setPen(QPen(line_color, 3))
                painter.drawLine(int(line_x), int(line_y), int(line_end_x), int(line_y))


class MainUI(QMainWindow):
    """主UI視窗"""
    
    def __init__(self, state_machine, communicator, user_mapper, medication_detector, config):
        """
        初始化UI
        
        Args:
            state_machine: 狀態機物件
            communicator: 串口通訊物件
            user_mapper: 使用者映射物件
            medication_detector: 服藥動作檢測物件
            config: 配置字典
        """
        super().__init__()
        
        self.state_machine = state_machine
        self.communicator = communicator
        self.user_mapper = user_mapper
        self.medication_detector = medication_detector
        self.config = config
        
        # 當前顯示的數據
        self.current_standby_data: Optional[Dict] = None
        self.current_vital_signs_data: Optional[Dict] = None
        
        # 指紋辨識結果（臨時保存）
        self.detected_fingerprint_id: Optional[int] = None
        self.detected_user_name: Optional[str] = None
        
        # CV畫面更新計時器
        self.cv_timer = QTimer()
        self.cv_timer.timeout.connect(self._update_cv_frame)
        self.cv_timer.start(100)  # 每100ms更新一次CV畫面
        
        # 動畫計時器
        self.animation_timer = QTimer()
        self.animation_timer.timeout.connect(self._update_animations)
        self.animation_timer.start(50)  # 約20fps（降低更新頻率讓動畫更慢）
        
        # 心跳動畫變數
        self.heartbeat_scale = 1.0
        self.heartbeat_direction = 1
        
        # 狀態轉換延遲計時器
        self.state_delay_timer = QTimer()
        self.state_delay_timer.setSingleShot(True)
        self.state_delay_timer.timeout.connect(self._handle_state_delay)
        self.pending_state: Optional[tuple] = None
        
        # 初始化UI
        self._init_ui()
        
        # 註冊狀態機回調
        self.state_machine.register_state_change_callback(self._on_state_changed)
        
        # 註冊串口通訊回調
        self._register_communicator_callbacks()
    
    def _init_ui(self):
        """初始化UI界面"""
        # 設置全螢幕
        if self.config.get('ui', {}).get('fullscreen', True):
            self.showFullScreen()
        else:
            resolution = self.config.get('ui', {}).get('resolution', {})
            self.resize(resolution.get('width', 1920), resolution.get('height', 1080))
        
        # 設置淺色背景（現代化設計）
        self.setStyleSheet("""
            QMainWindow {
                background-color: #f5f5f5;
            }
            QLabel {
                background-color: transparent;
            }
        """)
        
        # 創建中央widget
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        
        # 主布局
        main_layout = QVBoxLayout()
        main_layout.setContentsMargins(40, 30, 40, 30)
        main_layout.setSpacing(20)
        central_widget.setLayout(main_layout)
        
        # 創建各個UI組件
        self._create_header(main_layout)
        self._create_step_indicator(main_layout)
        self._create_main_content(main_layout)
        self._create_status_area(main_layout)
        
        # 動畫效果
        self.fade_animation = None
        self.pulse_animation = None
    
    def _create_header(self, parent_layout):
        """創建頂部標題區域"""
        header_widget = QWidget()
        header_layout = QHBoxLayout()
        header_widget.setLayout(header_layout)
        
        # 時間顯示
        self.time_label = QLabel()
        self.time_label.setAlignment(Qt.AlignmentFlag.AlignLeft | Qt.AlignmentFlag.AlignVCenter)
        font = QFont("Microsoft JhengHei", 24, QFont.Weight.Normal)
        self.time_label.setFont(font)
        self.time_label.setStyleSheet("color: #666666;")
        header_layout.addWidget(self.time_label)
        
        header_layout.addStretch()
        
        # 溫度顯示（待機模式）
        self.temp_label = QLabel("溫度: --°C")
        self.temp_label.setAlignment(Qt.AlignmentFlag.AlignRight | Qt.AlignmentFlag.AlignVCenter)
        font = QFont("Microsoft JhengHei", 24, QFont.Weight.Normal)
        self.temp_label.setFont(font)
        self.temp_label.setStyleSheet("color: #666666;")
        header_layout.addWidget(self.temp_label)
        
        parent_layout.addWidget(header_widget)
        
        # 更新時間的計時器
        self.time_timer = QTimer()
        self.time_timer.timeout.connect(self._update_time)
        self.time_timer.start(1000)  # 每秒更新
        self._update_time()
    
    def _create_step_indicator(self, parent_layout):
        """創建流程步驟指示器"""
        self.step_indicator = StepIndicator()
        self.step_indicator.set_current_step(0)
        parent_layout.addWidget(self.step_indicator)
    
    def _create_main_content(self, parent_layout):
        """創建主要內容區域"""
        content_widget = QWidget()
        content_layout = QVBoxLayout()
        content_layout.setSpacing(30)
        content_widget.setLayout(content_layout)
        
        # 主標題卡片
        title_card = QFrame()
        title_card.setStyleSheet("""
            QFrame {
                background-color: white;
                border-radius: 16px;
                padding: 30px;
            }
        """)
        title_layout = QVBoxLayout()
        title_card.setLayout(title_layout)
        
        self.title_label = QLabel("請將手指放在指紋辨識器上")
        self.title_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        font = QFont("Microsoft JhengHei", 48, QFont.Weight.Bold)
        self.title_label.setFont(font)
        self.title_label.setStyleSheet("color: #1a1a1a;")
        title_layout.addWidget(self.title_label)
        
        # 副標題/狀態（用於顯示心律血氧或狀態訊息）
        self.subtitle_label = QLabel("")
        self.subtitle_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        font = QFont("Microsoft JhengHei", 36, QFont.Weight.Bold)
        self.subtitle_label.setFont(font)
        self.subtitle_label.setStyleSheet("color: #2196F3;")  # 藍色，用於顯示心律血氧
        title_layout.addWidget(self.subtitle_label)
        
        content_layout.addWidget(title_card)
        
        # CV畫面顯示區域（用於顯示點陣圖效果）
        # 創建一個容器來居中CV畫面
        cv_container = QWidget()
        cv_container_layout = QHBoxLayout()
        cv_container_layout.setContentsMargins(0, 0, 0, 0)
        cv_container.setLayout(cv_container_layout)
        
        self.cv_label = QLabel()
        self.cv_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        # 設置固定大小，避免動畫效果（高度減少1/4，從960改為720）
        self.cv_label.setFixedSize(1280, 720)  # 固定大小，直接顯示
        self.cv_label.setStyleSheet("""
            QLabel {
                background-color: #c8c8c8;
                border-radius: 16px;
                border: 2px solid #e0e0e0;
            }
        """)
        self.cv_label.hide()  # 初始隱藏
        
        # 將CV標籤添加到容器中，並居中
        cv_container_layout.addStretch()
        cv_container_layout.addWidget(self.cv_label)
        cv_container_layout.addStretch()
        
        # 將容器添加到主布局
        content_layout.addWidget(cv_container)
        
        parent_layout.addWidget(content_widget, stretch=1)
    
    def _create_status_area(self, parent_layout):
        """創建狀態區域"""
        self.status_label = QLabel("系統就緒")
        self.status_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        font = QFont("Microsoft JhengHei", 18)
        self.status_label.setFont(font)
        self.status_label.setStyleSheet("color: #999999;")
        parent_layout.addWidget(self.status_label)
    
    def _update_time(self):
        """更新時間顯示"""
        current_time = datetime.now().strftime("%Y年%m月%d日 %H:%M:%S")
        self.time_label.setText(current_time)
    
    def _update_animations(self):
        """更新動畫效果"""
        # 心跳動畫（只在感測心律血氧時）
        current_state = self.state_machine.get_state()
        if current_state == SystemState.VITAL_SIGNS:
            # 心跳動畫：縮放效果（減小增量讓動畫更慢更平滑）
            self.heartbeat_scale += 0.01 * self.heartbeat_direction
            if self.heartbeat_scale >= 1.15:
                self.heartbeat_direction = -1
            elif self.heartbeat_scale <= 1.0:
                self.heartbeat_direction = 1
            
            # 應用縮放效果到副標題文字（顯示心律血氧的地方）
            font = self.subtitle_label.font()
            base_size = 36
            new_size = int(base_size * self.heartbeat_scale)
            font.setPointSize(new_size)
            self.subtitle_label.setFont(font)
    
    def _update_cv_frame(self):
        """更新CV畫面"""
        if self.medication_detector.is_detecting():
            frame = self.medication_detector.get_current_frame()
            if frame is not None:
                # 轉換OpenCV畫面為Qt格式
                height, width, channel = frame.shape
                bytes_per_line = 3 * width
                q_image = QImage(frame.data, width, height, bytes_per_line, QImage.Format.Format_RGB888).rgbSwapped()
                pixmap = QPixmap.fromImage(q_image)
                
                # 縮放以適應標籤大小
                scaled_pixmap = pixmap.scaled(
                    self.cv_label.size(), 
                    Qt.AspectRatioMode.KeepAspectRatio, 
                    Qt.TransformationMode.SmoothTransformation
                )
                self.cv_label.setPixmap(scaled_pixmap)
    
    def _register_communicator_callbacks(self):
        """註冊串口通訊回調"""
        # 待機模式數據
        self.communicator.register_callback('standby', self._on_standby_data)
        
        # 指紋辨識結果
        self.communicator.register_callback('detect_user', self._on_detect_user)
        
        # 工作模式開始
        self.communicator.register_callback('working_start', self._on_working_start)
        
        # 工作模式狀態
        self.communicator.register_callback('working_status', self._on_working_status)
        
        # 工作模式完成
        self.communicator.register_callback('working_final', self._on_working_final)
        
        # 工作模式錯誤
        self.communicator.register_callback('working_error', self._on_working_error)
    
    def _on_standby_data(self, data: Dict):
        """處理待機模式數據"""
        self.current_standby_data = data
        
        # 無論當前狀態如何，都更新溫度顯示（確保不會卡死）
        object_temp = data.get('object_temp', 0)
        ambient_temp = data.get('ambient_temp', 0)
        self.temp_label.setText(f"溫度: {object_temp:.1f}°C / {ambient_temp:.1f}°C")
        
        # 只有在待機狀態時才清空副標題
        if self.state_machine.get_state().value == 'standby':
            # 清空副標題（待機模式不顯示心律血氧）
            self.subtitle_label.setText("")
    
    def _on_detect_user(self, data: Dict):
        """處理指紋辨識結果"""
        logger.info(f"_on_detect_user 被調用，數據: {data}")
        # 確保在UI線程中執行
        # 使用 functools.partial 確保數據正確傳遞
        from functools import partial
        QTimer.singleShot(0, partial(self._do_detect_user, data))
    
    def _do_detect_user(self, data: Dict):
        """在UI線程中執行指紋辨識結果處理"""
        logger.info(f"_do_detect_user 開始執行，數據: {data}")
        fingerprint_id = data.get('fingerprint_id')
        if fingerprint_id:
            user_name = self.user_mapper.get_user_name(fingerprint_id)
            logger.info(f"辨識到使用者: {user_name} (ID: {fingerprint_id})")
            
            # 保存指紋信息
            self.detected_fingerprint_id = fingerprint_id
            self.detected_user_name = user_name
            
            # 轉換到 FINGERPRINT_OK 狀態，顯示用戶信息
            logger.info(f"準備轉換狀態到 FINGERPRINT_OK，當前狀態: {self.state_machine.get_state().value}")
            self.state_machine.set_state(
                SystemState.FINGERPRINT_OK,
                {'fingerprint_id': fingerprint_id, 'user_name': user_name}
            )
            logger.info(f"狀態已轉換到 FINGERPRINT_OK，新狀態: {self.state_machine.get_state().value}")
        else:
            logger.warning(f"未找到指紋ID: {data}")
    
    def _on_working_start(self):
        """處理工作模式開始（在 DETECT,USER 之後）"""
        # 確保在UI線程中執行
        QTimer.singleShot(0, lambda: self._do_working_start())
    
    def _do_working_start(self):
        """在UI線程中執行工作模式開始"""
        current_state = self.state_machine.get_state()
        logger.info(f"工作模式開始，當前狀態: {current_state.value}")
        
        # 如果已經在 FINGERPRINT_OK 狀態，延遲後會自動轉換到 VITAL_SIGNS
        # 如果還在 STANDBY 或 FINGERPRINT 狀態，等待 DETECT,USER 消息
        if current_state == SystemState.FINGERPRINT_OK:
            # 已經顯示用戶信息，等待延遲後自動轉換（由 _show_fingerprint_ok_screen 處理）
            logger.info("已在 FINGERPRINT_OK 狀態，等待自動轉換到 VITAL_SIGNS")
        elif current_state == SystemState.STANDBY or current_state == SystemState.FINGERPRINT:
            # 如果還沒有收到 DETECT,USER，先進入 FINGERPRINT 狀態
            if hasattr(self, 'detected_fingerprint_id') and self.detected_fingerprint_id:
                # 有指紋信息，轉換到 FINGERPRINT_OK
                self.state_machine.set_state(
                    SystemState.FINGERPRINT_OK,
                    {'fingerprint_id': self.detected_fingerprint_id, 'user_name': self.detected_user_name}
                )
            else:
                # 沒有指紋信息，進入 FINGERPRINT 狀態等待
                if current_state == SystemState.STANDBY:
                    self.state_machine.set_state(SystemState.FINGERPRINT)
    
    def _on_working_status(self, data: Dict):
        """處理工作模式狀態更新"""
        # 確保在UI線程中執行
        QTimer.singleShot(0, lambda: self._do_working_status(data))
    
    def _do_working_status(self, data: Dict):
        """在UI線程中執行工作模式狀態更新"""
        logger.info(f"_do_working_status 開始執行，數據: {data}")
        self.current_vital_signs_data = data
        
        current_state = self.state_machine.get_state()
        logger.info(f"當前狀態: {current_state.value}")
        
        # 如果當前是 FINGERPRINT 或 FINGERPRINT_OK 狀態，轉換到 VITAL_SIGNS
        if current_state == SystemState.FINGERPRINT or current_state == SystemState.FINGERPRINT_OK:
            # 取消之前的延遲轉換（如果有的話）
            if self.state_delay_timer.isActive():
                self.state_delay_timer.stop()
                logger.info("取消之前的延遲轉換")
            logger.info("收到 WORKING 狀態更新，立即轉換到心律血氧測量狀態")
            # 立即轉換到 VITAL_SIGNS
            self.state_machine.set_state(SystemState.VITAL_SIGNS)
            return
        
        if current_state == SystemState.VITAL_SIGNS:
            logger.info("當前在 VITAL_SIGNS 狀態，更新顯示")
            # 更新顯示
            object_temp = data.get('object_temp', 0)
            ambient_temp = data.get('ambient_temp', 0)
            self.temp_label.setText(f"溫度: {object_temp:.1f}°C / {ambient_temp:.1f}°C")
            
            # 顯示心律血氧（在標題卡片中顯示）
            heart_rate = data.get('heart_rate')
            spo2 = data.get('spo2')
            
            # 構建顯示文字
            if heart_rate == 'MEASURING' or spo2 == 'MEASURING':
                vital_text = "測量中..."
            elif isinstance(heart_rate, (int, str)) and isinstance(spo2, (int, str)):
                # 確保都是數字類型
                try:
                    hr_val = int(heart_rate) if isinstance(heart_rate, str) and heart_rate.isdigit() else heart_rate
                    spo2_val = int(spo2) if isinstance(spo2, str) and spo2.isdigit() else spo2
                    if isinstance(hr_val, int) and isinstance(spo2_val, int):
                        vital_text = f"心率: {hr_val} BPM  |  血氧: {spo2_val}%"
                    elif isinstance(hr_val, int):
                        vital_text = f"心率: {hr_val} BPM"
                    elif isinstance(spo2_val, int):
                        vital_text = f"血氧: {spo2_val}%"
                    else:
                        vital_text = "測量中..."
                except (ValueError, TypeError):
                    vital_text = "測量中..."
            elif isinstance(heart_rate, int):
                vital_text = f"心率: {heart_rate} BPM"
            elif isinstance(spo2, int):
                vital_text = f"血氧: {spo2}%"
            else:
                vital_text = "測量中..."
            
            # 在副標題中顯示心律血氧
            self.subtitle_label.setText(vital_text)
        else:
            logger.debug(f"當前狀態 {current_state.value} 不是 VITAL_SIGNS，跳過更新")
    
    def _on_working_final(self, data: Dict):
        """處理工作模式完成"""
        logger.info(f"_on_working_final 被調用，數據: {data}")
        # 確保在UI線程中執行
        from functools import partial
        QTimer.singleShot(0, partial(self._do_working_final, data))
    
    def _do_working_final(self, data: Dict):
        """在UI線程中執行工作模式完成處理"""
        logger.info(f"_do_working_final 開始執行，數據: {data}")
        fingerprint_id = data.get('fingerprint_id')
        user_name = self.user_mapper.get_user_name(fingerprint_id)
        
        logger.info(f"準備轉換狀態到 VITAL_SIGNS_OK，當前狀態: {self.state_machine.get_state().value}")
        # 更新狀態機
        self.state_machine.set_state(
            SystemState.VITAL_SIGNS_OK,
            {'fingerprint_id': fingerprint_id, 'user_name': user_name, **data}
        )
        logger.info(f"狀態已轉換到 VITAL_SIGNS_OK，新狀態: {self.state_machine.get_state().value}")
    
    def _on_working_error(self, error_type: str):
        """處理工作模式錯誤"""
        logger.info(f"_on_working_error 被調用，錯誤類型: {error_type}")
        # 確保在UI線程中執行
        from functools import partial
        QTimer.singleShot(0, partial(self._do_working_error, error_type))
    
    def _do_working_error(self, error_type: str):
        """在UI線程中執行工作模式錯誤處理"""
        logger.info(f"_do_working_error 開始執行，錯誤類型: {error_type}")
        current_state = self.state_machine.get_state()
        logger.info(f"當前狀態: {current_state.value}")
        
        if error_type == 'NO_FINGER':
            self.status_label.setText("錯誤: 未檢測到手指，請重新放置")
            logger.warning("未檢測到手指，返回待機模式")
        elif error_type == 'TIMEOUT':
            self.status_label.setText("錯誤: 測量超時，請重試")
            logger.warning("測量超時，返回待機模式")
        
        # 立即回到待機模式（不延遲，避免卡死）
        logger.info("準備返回待機模式")
        self.state_machine.set_state(SystemState.STANDBY)
        logger.info("已返回待機模式")
    
    def _on_state_changed(self, new_state, previous_state, data: Optional[Dict]):
        """處理狀態變更"""
        
        if new_state == SystemState.STANDBY:
            self._show_standby_screen()
        elif new_state == SystemState.FINGERPRINT:
            self._show_fingerprint_screen()
        elif new_state == SystemState.FINGERPRINT_OK:
            self._show_fingerprint_ok_screen(data)
        elif new_state == SystemState.VITAL_SIGNS:
            self._show_vital_signs_screen()
        elif new_state == SystemState.VITAL_SIGNS_OK:
            self._show_vital_signs_ok_screen(data)
        elif new_state == SystemState.MEDICATION:
            self._show_medication_screen(data)
        elif new_state == SystemState.MEDICATION_OK:
            self._show_medication_ok_screen()
        elif new_state == SystemState.COMPLETE:
            self._show_complete_screen()
    
    def _show_standby_screen(self):
        """顯示待機畫面"""
        self.title_label.setText("請將手指放在指紋辨識器上")
        self.subtitle_label.setText("")
        self.status_label.setText("系統就緒")
        self.cv_label.hide()
        self.step_indicator.set_current_step(0)
    
    def _show_fingerprint_screen(self):
        """顯示指紋辨識畫面（等待辨識中）"""
        self.title_label.setText("正在辨識指紋...")
        self.subtitle_label.setText("請保持手指穩定")
        self.status_label.setText("")
        self.step_indicator.set_current_step(0)
        # 這個狀態應該很快轉換，不需要設置延遲
    
    def _show_fingerprint_ok_screen(self, data: Dict):
        """顯示指紋辨識成功畫面"""
        user_name = data.get('user_name', '使用者')
        self.title_label.setText(f"{user_name}，您好！")
        self.subtitle_label.setText("身份確認成功")
        self.status_label.setText("")
        self.step_indicator.set_current_step(1)
        
        # 延遲2秒後進入下一階段
        self.pending_state = (SystemState.VITAL_SIGNS, None)
        self.state_delay_timer.start(2000)
    
    def _show_vital_signs_screen(self):
        """顯示心律血氧測量畫面"""
        self.title_label.setText("請將手指放在心律血氧感測器上")
        self.subtitle_label.setText("測量中...")
        self.status_label.setText("")
        self.cv_label.hide()
        self.step_indicator.set_current_step(2)
        # 重置心跳動畫
        self.heartbeat_scale = 1.0
        self.heartbeat_direction = 1
    
    def _show_vital_signs_ok_screen(self, data: Dict):
        """顯示測量完成畫面"""
        heart_rate = data.get('heart_rate', 0)
        spo2 = data.get('spo2', 0)
        self.title_label.setText("測量完成！")
        self.subtitle_label.setText(f"心率: {heart_rate} BPM  |  血氧: {spo2}%")
        self.status_label.setText("")
        
        # 延遲2秒後進入取藥階段
        fingerprint_id = data.get('fingerprint_id')
        if fingerprint_id:
            relay_num = self.user_mapper.get_user_relay(fingerprint_id)
            logger.info(f"準備進入取藥階段，使用者ID: {fingerprint_id}, 繼電器編號: {relay_num}")
            self.pending_state = (SystemState.MEDICATION, {'relay_num': relay_num, 'fingerprint_id': fingerprint_id})
            self.state_delay_timer.start(2000)
        else:
            logger.error("未找到指紋ID，無法進入取藥階段")
            # 如果沒有指紋ID，延遲後回到待機模式
            QTimer.singleShot(3000, lambda: self.state_machine.set_state(SystemState.STANDBY))
    
    def _show_medication_screen(self, data: Dict):
        """顯示取藥畫面"""
        relay_num = data.get('relay_num')
        fingerprint_id = data.get('fingerprint_id')
        
        logger.info(f"進入取藥階段，繼電器編號: {relay_num}, 使用者ID: {fingerprint_id}")
        
        self.title_label.setText("請確認已取藥")
        self.subtitle_label.setText("請將手部靠近嘴巴以確認服藥動作")
        self.status_label.setText("等待確認...")
        self.step_indicator.set_current_step(3)
        
        # 顯示CV畫面（直接顯示，不使用動畫）
        # 先設置固定大小，然後直接顯示，避免動畫效果（高度減少1/4）
        self.cv_label.setFixedSize(1280, 720)
        self.cv_label.show()
        self.cv_label.raise_()  # 確保CV畫面在最上層
        # 強制更新，確保立即顯示
        self.cv_label.update()
        logger.info("CV畫面已顯示")
        
        # 控制繼電器
        if relay_num:
            success = self.communicator.control_relay(relay_num)
            if success:
                logger.info(f"繼電器 {relay_num} 控制命令已發送")
            else:
                logger.error(f"繼電器 {relay_num} 控制命令發送失敗")
        else:
            logger.warning("未提供繼電器編號，跳過繼電器控制")
        
        # 啟動電腦視覺檢測
        def on_detected():
            logger.info("檢測到服藥動作，準備返回待機模式")
            # 使用 functools.partial 確保正確執行
            from functools import partial
            QTimer.singleShot(0, partial(self._handle_medication_detected))
        
        def on_timeout():
            logger.info("服藥動作檢測超時，準備返回待機模式")
            # 使用 functools.partial 確保正確執行
            from functools import partial
            QTimer.singleShot(0, partial(self._handle_medication_timeout))
        
        self.medication_detector.start_detection(on_detected, on_timeout)
    
    def _handle_medication_detected(self):
        """處理檢測到服藥動作"""
        logger.info("_handle_medication_detected 開始執行")
        # 停止檢測
        self.medication_detector.stop_detection()
        # 獲取當前使用者信息
        current_state = self.state_machine.get_state()
        fingerprint_id = None
        user_name = None
        
        # 從狀態機獲取使用者信息
        if hasattr(self, 'detected_fingerprint_id') and self.detected_fingerprint_id:
            fingerprint_id = self.detected_fingerprint_id
            user_name = self.detected_user_name
        
        # 轉換到完成狀態，顯示完成訊息
        logger.info(f"準備顯示完成畫面，使用者: {user_name}")
        self.state_machine.set_state(
            SystemState.COMPLETE,
            {'fingerprint_id': fingerprint_id, 'user_name': user_name}
        )
        logger.info("已轉換到完成狀態")
    
    def _handle_medication_timeout(self):
        """處理檢測超時"""
        logger.info("_handle_medication_timeout 開始執行")
        # 停止檢測
        self.medication_detector.stop_detection()
        # 獲取當前使用者信息
        fingerprint_id = None
        user_name = None
        
        # 從狀態機獲取使用者信息
        if hasattr(self, 'detected_fingerprint_id') and self.detected_fingerprint_id:
            fingerprint_id = self.detected_fingerprint_id
            user_name = self.detected_user_name
        
        # 轉換到完成狀態，顯示完成訊息
        logger.info(f"準備顯示完成畫面，使用者: {user_name}")
        self.state_machine.set_state(
            SystemState.COMPLETE,
            {'fingerprint_id': fingerprint_id, 'user_name': user_name}
        )
        logger.info("已轉換到完成狀態")
    
    def _show_medication_ok_screen(self):
        """顯示取藥完成畫面（這個狀態現在不會被使用，因為直接返回待機）"""
        logger.info("_show_medication_ok_screen 被調用（應該不會執行到這裡）")
        # 直接返回待機模式
        self.cv_label.hide()
        self.medication_detector.stop_detection()
        self.state_machine.set_state(SystemState.STANDBY)
    
    def _show_complete_screen(self, data: Optional[Dict] = None):
        """顯示完成畫面"""
        logger.info(f"_show_complete_screen 被調用，數據: {data}")
        # 獲取使用者信息
        user_name = "使用者"
        if data:
            user_name = data.get('user_name', '使用者')
        elif hasattr(self, 'detected_user_name') and self.detected_user_name:
            user_name = self.detected_user_name
        
        # 獲取當前時間
        current_time = datetime.now().strftime("%Y年%m月%d日 %H:%M:%S")
        
        # 顯示完成訊息
        self.title_label.setText(f"{user_name}登錄完畢")
        self.subtitle_label.setText(current_time)
        self.status_label.setText("")
        self.cv_label.hide()
        self.step_indicator.set_current_step(0)  # 重置步驟指示器
        
        logger.info(f"顯示完成畫面：{user_name}登錄完畢，時間：{current_time}")
        
        # 延遲3秒後回到待機模式
        self.pending_state = (SystemState.STANDBY, None)
        self.state_delay_timer.start(3000)
        logger.info("3秒後將返回待機模式")
    
    def _handle_state_delay(self):
        """處理狀態延遲轉換"""
        if self.pending_state:
            new_state, data = self.pending_state
            self.state_machine.set_state(new_state, data)
            self.pending_state = None
    
    def closeEvent(self, event):
        """關閉事件"""
        self.animation_timer.stop()
        self.time_timer.stop()
        self.cv_timer.stop()
        self.state_delay_timer.stop()
        self.medication_detector.stop_detection()
        event.accept()
