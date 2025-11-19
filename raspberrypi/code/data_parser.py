#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
數據解析模組
負責解析BMduino傳來的各種訊息格式
"""

from typing import Dict, Optional, Union
import logging

logger = logging.getLogger(__name__)


class DataParser:
    """數據解析類別"""
    
    @staticmethod
    def parse_standby(line: str) -> Optional[Dict]:
        """
        解析待機模式數據
        
        格式: STANDBY,物體溫度,環境溫度,心率,血氧
        
        Args:
            line: 待解析的字串
        
        Returns:
            解析後的字典，失敗返回None
        """
        try:
            parts = line.split(',')
            if len(parts) < 5:
                return None
            
            return {
                'mode': 'standby',
                'object_temp': float(parts[1]),
                'ambient_temp': float(parts[2]),
                'heart_rate': int(parts[3]) if parts[3] != '0' else None,
                'spo2': int(parts[4]) if parts[4] != '0' else None
            }
        except (ValueError, IndexError) as e:
            logger.warning(f"解析待機模式數據失敗: {line}, 錯誤: {e}")
            return None
    
    @staticmethod
    def parse_working_start(line: str) -> bool:
        """
        解析工作模式開始訊息
        
        格式: WORKING,START
        
        Args:
            line: 待解析的字串
        
        Returns:
            是否為工作模式開始
        """
        return line.strip() == 'WORKING,START'
    
    @staticmethod
    def parse_working_status(line: str) -> Optional[Dict]:
        """
        解析工作模式狀態更新
        
        格式: WORKING,物體溫度,環境溫度,心率,血氧
        心率/血氧可能是 'MEASURING' 或數字
        
        Args:
            line: 待解析的字串
        
        Returns:
            解析後的字典，失敗返回None
        """
        try:
            parts = line.split(',')
            if len(parts) < 5:
                return None
            
            # 解析心率
            heart_rate: Union[str, int, None] = None
            if parts[3] == 'MEASURING':
                heart_rate = 'MEASURING'
            elif parts[3] != '0':
                try:
                    heart_rate = int(parts[3])
                except ValueError:
                    heart_rate = 'MEASURING'
            
            # 解析血氧
            spo2: Union[str, int, None] = None
            if parts[4] == 'MEASURING':
                spo2 = 'MEASURING'
            elif parts[4] != '0':
                try:
                    spo2 = int(parts[4])
                except ValueError:
                    spo2 = 'MEASURING'
            
            return {
                'mode': 'working',
                'object_temp': float(parts[1]),
                'ambient_temp': float(parts[2]),
                'heart_rate': heart_rate,
                'spo2': spo2
            }
        except (ValueError, IndexError) as e:
            logger.warning(f"解析工作模式狀態失敗: {line}, 錯誤: {e}")
            return None
    
    @staticmethod
    def parse_working_final(line: str) -> Optional[Dict]:
        """
        解析工作模式完成數據
        
        格式: WORKING,FINAL,指紋ID,物體溫度,環境溫度,心率,血氧
        
        Args:
            line: 待解析的字串
        
        Returns:
            解析後的字典，失敗返回None
        """
        try:
            parts = line.split(',')
            if len(parts) < 7:
                return None
            
            return {
                'mode': 'working_final',
                'fingerprint_id': int(parts[2]),
                'object_temp': float(parts[3]),
                'ambient_temp': float(parts[4]),
                'heart_rate': int(parts[5]),
                'spo2': int(parts[6])
            }
        except (ValueError, IndexError) as e:
            logger.warning(f"解析工作模式完成數據失敗: {line}, 錯誤: {e}")
            return None
    
    @staticmethod
    def parse_working_error(line: str) -> Optional[str]:
        """
        解析工作模式錯誤訊息
        
        格式: WORKING,NO_FINGER 或 WORKING,TIMEOUT
        
        Args:
            line: 待解析的字串
        
        Returns:
            錯誤類型，失敗返回None
        """
        if 'NO_FINGER' in line:
            return 'NO_FINGER'
        elif 'TIMEOUT' in line:
            return 'TIMEOUT'
        return None
    
    @staticmethod
    def parse_relay_ok(line: str) -> Optional[int]:
        """
        解析繼電器控制成功訊息
        
        格式: RELAY_OK,繼電器編號
        
        Args:
            line: 待解析的字串
        
        Returns:
            繼電器編號，失敗返回None
        """
        try:
            parts = line.split(',')
            if len(parts) >= 2:
                return int(parts[1])
        except (ValueError, IndexError) as e:
            logger.warning(f"解析繼電器訊息失敗: {line}, 錯誤: {e}")
        return None
    
    @staticmethod
    def parse_detect_user(line: str) -> Optional[Dict]:
        """
        解析指紋辨識結果訊息
        
        格式: DETECT,USER1 或 DETECT,USER2 等
        
        Args:
            line: 待解析的字串
        
        Returns:
            解析後的字典，包含 fingerprint_id，失敗返回None
        """
        try:
            parts = line.split(',')
            if len(parts) >= 2 and parts[0] == 'DETECT':
                # 提取 USER 後面的數字
                user_str = parts[1]
                if user_str.startswith('USER'):
                    fingerprint_id = int(user_str[4:])  # 跳過 "USER" 四個字符
                    return {
                        'mode': 'detect_user',
                        'fingerprint_id': fingerprint_id
                    }
        except (ValueError, IndexError) as e:
            logger.warning(f"解析指紋辨識結果失敗: {line}, 錯誤: {e}")
        return None
    
    @staticmethod
    def parse_message(line: str) -> Optional[Dict]:
        """
        通用解析函數，自動判斷訊息類型
        
        Args:
            line: 待解析的字串
        
        Returns:
            解析後的字典，失敗返回None
        """
        line = line.strip()
        
        if line.startswith('STANDBY,'):
            return DataParser.parse_standby(line)
        elif line.startswith('DETECT,USER'):
            return DataParser.parse_detect_user(line)
        elif line == 'WORKING,START':
            return {'mode': 'working_start'}
        elif line.startswith('WORKING,FINAL,'):
            return DataParser.parse_working_final(line)
        elif line.startswith('WORKING,'):
            error = DataParser.parse_working_error(line)
            if error:
                return {'mode': 'working_error', 'error': error}
            return DataParser.parse_working_status(line)
        elif line.startswith('RELAY_OK,'):
            relay_num = DataParser.parse_relay_ok(line)
            if relay_num:
                return {'mode': 'relay_ok', 'relay_num': relay_num}
        
        return None

