#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
串口通訊模組
負責與BMduino進行通訊
"""

import serial
import threading
import time
from typing import Optional, Callable, List
import logging

logger = logging.getLogger(__name__)


class BMduinoCommunicator:
    """BMduino 通訊類別"""
    
    def __init__(self, port: str = "/dev/ttyACM0", baudrate: int = 115200):
        """
        初始化串口通訊
        
        Args:
            port: 串口路徑
            baudrate: 波特率
        """
        self.port = port
        self.baudrate = baudrate
        self.ser: Optional[serial.Serial] = None
        self.running = False
        self.listen_thread: Optional[threading.Thread] = None
        
        # 回調函數列表
        self.callbacks = {
            'standby': [],
            'detect_user': [],  # 指紋辨識結果
            'working_start': [],
            'working_status': [],
            'working_final': [],
            'working_error': [],
            'relay_ok': [],
            'raw_message': []  # 原始訊息回調（用於調試）
        }
        
        # 連接狀態
        self.connected = False
        self.reconnect_interval = 5  # 重連間隔（秒）
    
    def register_callback(self, event: str, callback: Callable):
        """
        註冊回調函數
        
        Args:
            event: 事件類型 ('standby', 'detect_user', 'working_start', 'working_status', 'working_final', 'working_error', 'relay_ok', 'raw_message')
            callback: 回調函數
        """
        if event in self.callbacks:
            self.callbacks[event].append(callback)
            logger.debug(f"已註冊回調: {event}")
        else:
            logger.warning(f"未知的事件類型: {event}，可用的類型: {list(self.callbacks.keys())}")
    
    def connect(self) -> bool:
        """
        連接串口
        
        Returns:
            是否連接成功
        """
        try:
            if self.ser and self.ser.is_open:
                self.ser.close()
            
            self.ser = serial.Serial(
                self.port,
                self.baudrate,
                timeout=1,
                write_timeout=1
            )
            
            # 清空緩衝區
            self.ser.reset_input_buffer()
            self.ser.reset_output_buffer()
            
            time.sleep(0.5)  # 等待串口穩定
            
            self.connected = True
            logger.info(f"串口連接成功: {self.port}")
            return True
            
        except serial.SerialException as e:
            logger.error(f"串口連接失敗: {e}")
            self.connected = False
            return False
        except Exception as e:
            logger.error(f"連接時發生錯誤: {e}")
            self.connected = False
            return False
    
    def disconnect(self):
        """斷開串口連接"""
        self.stop_listening()
        if self.ser and self.ser.is_open:
            self.ser.close()
        self.connected = False
        logger.info("串口已斷開")
    
    def start_listening(self):
        """開始監聽串口數據"""
        if self.running:
            logger.warning("監聽線程已在運行")
            return
        
        if not self.connected:
            if not self.connect():
                logger.error("無法連接串口，無法開始監聽")
                return
        
        self.running = True
        self.listen_thread = threading.Thread(target=self._listen_loop, daemon=True)
        self.listen_thread.start()
        logger.info("開始監聽串口數據")
    
    def stop_listening(self):
        """停止監聽"""
        self.running = False
        if self.listen_thread:
            self.listen_thread.join(timeout=2)
        logger.info("停止監聽串口數據")
    
    def _listen_loop(self):
        """監聽迴圈（在獨立線程中運行）"""
        while self.running:
            try:
                if not self.connected or not self.ser or not self.ser.is_open:
                    # 嘗試重連
                    time.sleep(self.reconnect_interval)
                    if self.running:
                        self.connect()
                    continue
                
                if self.ser.in_waiting > 0:
                    try:
                        line = self.ser.readline().decode('utf-8', errors='ignore').strip()
                        if line:
                            # 記錄收到的原始訊息（用於調試）
                            logger.debug(f"收到原始訊息: {line}")
                            
                            # 觸發原始訊息回調
                            for callback in self.callbacks['raw_message']:
                                try:
                                    callback(line)
                                except Exception as e:
                                    logger.error(f"回調函數執行錯誤: {e}")
                            
                            # 處理訊息
                            self._process_message(line)
                    except UnicodeDecodeError:
                        logger.warning("解碼錯誤，跳過該行")
                    except Exception as e:
                        logger.error(f"處理訊息時發生錯誤: {e}")
                
                time.sleep(0.01)  # 避免CPU占用過高
                
            except serial.SerialException as e:
                logger.error(f"串口錯誤: {e}")
                self.connected = False
                time.sleep(self.reconnect_interval)
            except Exception as e:
                logger.error(f"監聽迴圈錯誤: {e}")
                time.sleep(1)
    
    def _process_message(self, line: str):
        """
        處理接收到的訊息
        
        Args:
            line: 接收到的訊息行
        """
        try:
            if line.startswith('STANDBY,'):
                # 待機模式數據
                parts = line.split(',')
                if len(parts) >= 5:
                    data = {
                        'object_temp': float(parts[1]),
                        'ambient_temp': float(parts[2]),
                        'heart_rate': int(parts[3]) if parts[3] != '0' else None,
                        'spo2': int(parts[4]) if parts[4] != '0' else None
                    }
                    for callback in self.callbacks['standby']:
                        try:
                            callback(data)
                        except Exception as e:
                            logger.error(f"待機模式回調錯誤: {e}")
            
            elif line.startswith('DETECT,USER'):
                # 指紋辨識結果（格式：DETECT,USER1 或 DETECT,USER2 等）
                logger.info(f"收到指紋辨識消息: {line}")
                parts = line.split(',')
                logger.info(f"分割後的parts: {parts}, 長度: {len(parts)}")
                if len(parts) >= 2:
                    user_str = parts[1].strip()  # 移除換行符等空白字符
                    logger.info(f"解析用戶字符串: '{user_str}'")
                    if user_str.startswith('USER'):
                        logger.info(f"用戶字符串以USER開頭，準備解析ID")
                        try:
                            fingerprint_id = int(user_str[4:])  # 跳過 "USER" 四個字符
                            logger.info(f"解析到指紋ID: {fingerprint_id}")
                            data = {'fingerprint_id': fingerprint_id}
                            logger.info(f"準備調用 detect_user 回調，回調數量: {len(self.callbacks['detect_user'])}")
                            if len(self.callbacks['detect_user']) == 0:
                                logger.warning("detect_user 回調列表為空！")
                            for callback in self.callbacks['detect_user']:
                                try:
                                    logger.info(f"調用 detect_user 回調: {callback}")
                                    callback(data)
                                    logger.info(f"detect_user 回調執行完成")
                                except Exception as e:
                                    logger.error(f"指紋辨識回調錯誤: {e}", exc_info=True)
                        except ValueError as e:
                            logger.error(f"無法解析指紋ID: {user_str}, 錯誤: {e}", exc_info=True)
                    else:
                        # 如果格式不對，嘗試直接解析為數字
                        logger.warning(f"用戶字符串 '{user_str}' 不以USER開頭，嘗試直接解析為數字")
                        try:
                            fingerprint_id = int(user_str)
                            logger.info(f"直接解析到指紋ID: {fingerprint_id}")
                            data = {'fingerprint_id': fingerprint_id}
                            logger.info(f"準備調用 detect_user 回調，回調數量: {len(self.callbacks['detect_user'])}")
                            if len(self.callbacks['detect_user']) == 0:
                                logger.warning("detect_user 回調列表為空！")
                            for callback in self.callbacks['detect_user']:
                                try:
                                    logger.info(f"調用 detect_user 回調: {callback}")
                                    callback(data)
                                    logger.info(f"detect_user 回調執行完成")
                                except Exception as e:
                                    logger.error(f"指紋辨識回調錯誤: {e}", exc_info=True)
                        except ValueError as e:
                            logger.error(f"無法解析指紋ID: {user_str}, 錯誤: {e}", exc_info=True)
                else:
                    logger.warning(f"DETECT,USER 消息格式錯誤: {line}")
            
            elif line == 'WORKING,START':
                # 進入工作模式
                for callback in self.callbacks['working_start']:
                    try:
                        callback()
                    except Exception as e:
                        logger.error(f"工作模式開始回調錯誤: {e}")
            
            elif line.startswith('WORKING,FINAL,'):
                # 工作模式完成（格式：WORKING,FINAL,指紋ID,物體溫度,環境溫度,心率,血氧）
                logger.info(f"收到 WORKING,FINAL 消息: {line}")
                parts = line.split(',')
                logger.info(f"分割後的parts: {parts}, 長度: {len(parts)}")
                if len(parts) >= 7:
                    try:
                        data = {
                            'fingerprint_id': int(parts[2]),
                            'object_temp': float(parts[3]),
                            'ambient_temp': float(parts[4]),
                            'heart_rate': int(parts[5]),
                            'spo2': int(parts[6])
                        }
                        logger.info(f"解析後的數據: {data}")
                        logger.info(f"準備調用 working_final 回調，回調數量: {len(self.callbacks['working_final'])}")
                        for callback in self.callbacks['working_final']:
                            try:
                                logger.info(f"調用 working_final 回調: {callback}")
                                callback(data)
                                logger.info(f"working_final 回調執行完成")
                            except Exception as e:
                                logger.error(f"工作模式完成回調錯誤: {e}", exc_info=True)
                    except (ValueError, IndexError) as e:
                        logger.error(f"解析 WORKING,FINAL 失敗: {line}, 錯誤: {e}", exc_info=True)
                else:
                    logger.warning(f"WORKING,FINAL 格式錯誤: {line}, 期望至少7個部分，實際{len(parts)}個")
            
            elif line.startswith('WORKING,NO_FINGER') or line.startswith('WORKING,TIMEOUT'):
                # 工作模式錯誤（必須在 WORKING, 之前檢查，避免被當作狀態更新）
                logger.info(f"收到工作模式錯誤消息: {line}")
                error_type = 'NO_FINGER' if 'NO_FINGER' in line else 'TIMEOUT'
                logger.info(f"錯誤類型: {error_type}")
                logger.info(f"準備調用 working_error 回調，回調數量: {len(self.callbacks['working_error'])}")
                for callback in self.callbacks['working_error']:
                    try:
                        logger.info(f"調用 working_error 回調: {callback}")
                        callback(error_type)
                        logger.info(f"working_error 回調執行完成")
                    except Exception as e:
                        logger.error(f"工作模式錯誤回調錯誤: {e}", exc_info=True)
            
            elif line.startswith('WORKING,'):
                # 工作模式狀態更新（格式：WORKING,物體溫度,環境溫度,心率,血氧）
                logger.info(f"收到 WORKING 狀態更新: {line}")
                parts = line.split(',')
                logger.info(f"分割後的parts: {parts}, 長度: {len(parts)}")
                if len(parts) == 5:
                    try:
                        # 解析心率（可能是 'MEASURING' 或數字字符串）
                        heart_rate = parts[3].strip()
                        if heart_rate == 'MEASURING':
                            heart_rate = 'MEASURING'
                        else:
                            try:
                                heart_rate = int(heart_rate)
                            except ValueError:
                                heart_rate = 'MEASURING'
                        
                        # 解析血氧（可能是 'MEASURING' 或數字字符串）
                        spo2 = parts[4].strip()
                        if spo2 == 'MEASURING':
                            spo2 = 'MEASURING'
                        else:
                            try:
                                spo2 = int(spo2)
                            except ValueError:
                                spo2 = 'MEASURING'
                        
                        data = {
                            'object_temp': float(parts[1]),
                            'ambient_temp': float(parts[2]),
                            'heart_rate': heart_rate,
                            'spo2': spo2
                        }
                        logger.info(f"解析後的數據: {data}")
                        logger.info(f"準備調用 working_status 回調，回調數量: {len(self.callbacks['working_status'])}")
                        for callback in self.callbacks['working_status']:
                            try:
                                logger.info(f"調用 working_status 回調: {callback}")
                                callback(data)
                                logger.info(f"working_status 回調執行完成")
                            except Exception as e:
                                logger.error(f"工作模式狀態回調錯誤: {e}", exc_info=True)
                    except (ValueError, IndexError) as e:
                        logger.error(f"解析 WORKING 狀態更新失敗: {line}, 錯誤: {e}", exc_info=True)
                else:
                    logger.warning(f"WORKING 狀態更新格式錯誤: {line}, 期望5個部分，實際{len(parts)}個")
            
            
            elif line.startswith('RELAY_OK,'):
                # 繼電器控制成功
                parts = line.split(',')
                if len(parts) >= 2:
                    relay_num = int(parts[1])
                    for callback in self.callbacks['relay_ok']:
                        try:
                            callback(relay_num)
                        except Exception as e:
                            logger.error(f"繼電器回調錯誤: {e}")
        
        except ValueError as e:
            logger.warning(f"數據解析錯誤: {line}, 錯誤: {e}")
        except Exception as e:
            logger.error(f"處理訊息時發生未預期錯誤: {e}")
    
    def control_relay(self, relay_num: int) -> bool:
        """
        控制繼電器
        
        Args:
            relay_num: 繼電器編號 (1-4)
        
        Returns:
            是否發送成功
        """
        if relay_num < 1 or relay_num > 4:
            logger.error(f"無效的繼電器編號: {relay_num}")
            return False
        
        if not self.connected or not self.ser or not self.ser.is_open:
            logger.error("串口未連接，無法發送命令")
            return False
        
        try:
            command = f"RELAY,{relay_num}\n"
            self.ser.write(command.encode('utf-8'))
            logger.info(f"發送繼電器控制命令: {command.strip()}")
            return True
        except Exception as e:
            logger.error(f"發送命令失敗: {e}")
            return False
    
    def is_connected(self) -> bool:
        """檢查是否已連接"""
        return self.connected and self.ser is not None and self.ser.is_open

