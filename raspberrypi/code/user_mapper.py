#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
使用者映射模組
負責指紋ID與使用者資訊的對應
"""

import json
from pathlib import Path
from typing import Dict, Optional
import logging

logger = logging.getLogger(__name__)


class UserMapper:
    """使用者映射類別"""
    
    def __init__(self, config_path: str = "data/user_config.json"):
        """
        初始化使用者映射
        
        Args:
            config_path: 使用者配置檔案路徑
        """
        self.config_path = config_path
        self.users: Dict[str, Dict] = {}
        self._load_config()
    
    def _load_config(self):
        """載入使用者配置"""
        try:
            config_file = Path(self.config_path)
            if config_file.exists():
                with open(config_file, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                    self.users = config.get('users', {})
                logger.info(f"載入使用者配置: {len(self.users)} 位使用者")
            else:
                logger.warning(f"使用者配置檔案不存在: {self.config_path}")
                # 創建預設配置
                self._create_default_config()
        except json.JSONDecodeError as e:
            logger.error(f"解析使用者配置檔案失敗: {e}")
            self._create_default_config()
        except Exception as e:
            logger.error(f"載入使用者配置失敗: {e}")
            self._create_default_config()
    
    def _create_default_config(self):
        """創建預設配置"""
        self.users = {
            "1": {"name": "使用者1號", "relay": 1},
            "2": {"name": "使用者2號", "relay": 2},
            "3": {"name": "使用者3號", "relay": 3},
            "4": {"name": "使用者4號", "relay": 4}
        }
        logger.info("使用預設使用者配置")
    
    def get_user_name(self, fingerprint_id: int) -> str:
        """
        根據指紋ID獲取使用者名稱
        
        Args:
            fingerprint_id: 指紋ID
        
        Returns:
            使用者名稱，找不到返回 "未知使用者"
        """
        user_id = str(fingerprint_id)
        if user_id in self.users:
            return self.users[user_id].get('name', f"使用者{fingerprint_id}號")
        return f"使用者{fingerprint_id}號"
    
    def get_user_relay(self, fingerprint_id: int) -> Optional[int]:
        """
        根據指紋ID獲取對應的繼電器編號
        
        Args:
            fingerprint_id: 指紋ID
        
        Returns:
            繼電器編號，找不到返回None
        """
        user_id = str(fingerprint_id)
        if user_id in self.users:
            return self.users[user_id].get('relay')
        return None
    
    def get_user_info(self, fingerprint_id: int) -> Optional[Dict]:
        """
        獲取完整的使用者資訊
        
        Args:
            fingerprint_id: 指紋ID
        
        Returns:
            使用者資訊字典，找不到返回None
        """
        user_id = str(fingerprint_id)
        if user_id in self.users:
            info = self.users[user_id].copy()
            info['fingerprint_id'] = fingerprint_id
            return info
        return None
    
    def get_all_users(self) -> Dict[str, Dict]:
        """
        獲取所有使用者資訊
        
        Returns:
            所有使用者的字典
        """
        return self.users.copy()

