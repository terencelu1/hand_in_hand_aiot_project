#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
狀態機模組
管理UI流程的狀態轉換
"""

from enum import Enum
from typing import Optional, Callable
import logging

logger = logging.getLogger(__name__)


class SystemState(Enum):
    """系統狀態枚舉"""
    STANDBY = "standby"                    # 待機模式
    FINGERPRINT = "fingerprint"            # 等待指紋辨識
    FINGERPRINT_OK = "fingerprint_ok"      # 指紋辨識成功
    VITAL_SIGNS = "vital_signs"            # 測量心律血氧
    VITAL_SIGNS_OK = "vital_signs_ok"      # 測量完成
    MEDICATION = "medication"              # 等待取藥
    MEDICATION_OK = "medication_ok"        # 取藥完成
    COMPLETE = "complete"                  # 完成流程


class StateMachine:
    """狀態機類別"""
    
    def __init__(self):
        """初始化狀態機"""
        self.current_state = SystemState.STANDBY
        self.previous_state: Optional[SystemState] = None
        
        # 狀態轉換回調
        self.state_change_callbacks: list[Callable] = []
        
        # 當前數據
        self.current_data = {
            'standby_data': None,
            'fingerprint_id': None,
            'user_name': None,
            'vital_signs_data': None,
            'final_data': None
        }
    
    def register_state_change_callback(self, callback: Callable):
        """
        註冊狀態變更回調
        
        Args:
            callback: 回調函數，參數為 (new_state, previous_state)
        """
        self.state_change_callbacks.append(callback)
    
    def set_state(self, new_state: SystemState, data: Optional[dict] = None):
        """
        設置新狀態
        
        Args:
            new_state: 新狀態
            data: 狀態相關數據
        """
        if new_state == self.current_state:
            return
        
        self.previous_state = self.current_state
        self.current_state = new_state
        
        # 更新數據
        if data:
            if new_state == SystemState.STANDBY:
                self.current_data['standby_data'] = data
            elif new_state == SystemState.FINGERPRINT_OK:
                self.current_data['fingerprint_id'] = data.get('fingerprint_id')
                self.current_data['user_name'] = data.get('user_name')
            elif new_state == SystemState.VITAL_SIGNS:
                self.current_data['vital_signs_data'] = data
            elif new_state == SystemState.VITAL_SIGNS_OK:
                self.current_data['final_data'] = data
        
        logger.info(f"狀態轉換: {self.previous_state.value} -> {self.current_state.value}")
        
        # 觸發回調
        for callback in self.state_change_callbacks:
            try:
                callback(self.current_state, self.previous_state, data)
            except Exception as e:
                logger.error(f"狀態變更回調錯誤: {e}")
    
    def get_state(self) -> SystemState:
        """獲取當前狀態"""
        return self.current_state
    
    def get_previous_state(self) -> Optional[SystemState]:
        """獲取上一個狀態"""
        return self.previous_state
    
    def reset(self):
        """重置狀態機到待機模式"""
        self.set_state(SystemState.STANDBY)
        self.current_data = {
            'standby_data': None,
            'fingerprint_id': None,
            'user_name': None,
            'vital_signs_data': None,
            'final_data': None
        }
        logger.info("狀態機已重置")

