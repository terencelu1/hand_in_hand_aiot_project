#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
API服務器模組
提供REST API供手機APP使用
"""

from flask import Flask, jsonify, request
from flask_cors import CORS
import threading
from typing import Optional, Dict, Any
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


class APIServer:
    """API服務器類別"""
    
    def __init__(self, host: str = "0.0.0.0", port: int = 5000):
        """
        初始化API服務器
        
        Args:
            host: 監聽地址
            port: 監聽端口
        """
        self.host = host
        self.port = port
        self.app = Flask(__name__)
        CORS(self.app)  # 允許跨域請求
        
        # 數據提供者（由外部設置）
        self.data_provider: Optional[Any] = None
        self.database: Optional[Any] = None
        
        # 當前狀態
        self.current_status: Dict[str, Any] = {
            'mode': 'standby',
            'data': None
        }
        
        # 設置路由
        self._setup_routes()
        
        # 服務器線程
        self.server_thread: Optional[threading.Thread] = None
        self.running = False
    
    def _setup_routes(self):
        """設置API路由"""
        
        @self.app.route('/api/status', methods=['GET'])
        def get_status():
            """獲取當前系統狀態"""
            try:
                return jsonify({
                    'success': True,
                    'status': self.current_status
                })
            except Exception as e:
                logger.error(f"獲取狀態錯誤: {e}")
                return jsonify({
                    'success': False,
                    'error': str(e)
                }), 500
        
        @self.app.route('/api/latest', methods=['GET'])
        def get_latest():
            """獲取最新一次測量數據"""
            try:
                user_id = request.args.get('user_id', type=int)
                
                if self.database:
                    latest = self.database.get_latest_measurement(user_id)
                    if latest:
                        # 優化數據格式：添加易讀的時間戳和使用者名稱
                        enhanced_record = latest.copy()
                        
                        # 解析ISO時間戳並轉換為易讀格式
                        try:
                            timestamp_obj = datetime.fromisoformat(latest['timestamp'])
                            enhanced_record['timestamp_readable'] = timestamp_obj.strftime('%Y年%m月%d日 %H:%M:%S')
                            enhanced_record['date'] = timestamp_obj.strftime('%Y-%m-%d')
                            enhanced_record['time'] = timestamp_obj.strftime('%H:%M:%S')
                        except (ValueError, KeyError):
                            enhanced_record['timestamp_readable'] = latest.get('timestamp', '')
                            enhanced_record['date'] = ''
                            enhanced_record['time'] = ''
                        
                        # 添加使用者名稱
                        if self.data_provider and hasattr(self.data_provider, 'user_mapper'):
                            user_name = self.data_provider.user_mapper.get_user_name(latest.get('user_id', 0))
                            enhanced_record['user_name'] = user_name
                        else:
                            enhanced_record['user_name'] = f"使用者{latest.get('user_id', 0)}號"
                        
                        return jsonify({
                            'success': True,
                            'data': enhanced_record
                        })
                    else:
                        return jsonify({
                            'success': True,
                            'data': None,
                            'message': '暫無數據'
                        })
                else:
                    return jsonify({
                        'success': False,
                        'error': '數據庫未初始化'
                    }), 500
            except Exception as e:
                logger.error(f"獲取最新數據錯誤: {e}")
                return jsonify({
                    'success': False,
                    'error': str(e)
                }), 500
        
        @self.app.route('/api/history', methods=['GET'])
        def get_history():
            """獲取歷史數據"""
            try:
                user_id = request.args.get('user_id', type=int)
                limit = request.args.get('limit', default=100, type=int)
                
                if self.database:
                    history = self.database.get_history(user_id, limit)
                    
                    # 優化數據格式：添加易讀的時間戳和使用者名稱
                    enhanced_history = []
                    for record in history:
                        enhanced_record = record.copy()
                        
                        # 解析ISO時間戳並轉換為易讀格式
                        try:
                            timestamp_obj = datetime.fromisoformat(record['timestamp'])
                            enhanced_record['timestamp_readable'] = timestamp_obj.strftime('%Y年%m月%d日 %H:%M:%S')
                            enhanced_record['date'] = timestamp_obj.strftime('%Y-%m-%d')
                            enhanced_record['time'] = timestamp_obj.strftime('%H:%M:%S')
                        except (ValueError, KeyError):
                            enhanced_record['timestamp_readable'] = record.get('timestamp', '')
                            enhanced_record['date'] = ''
                            enhanced_record['time'] = ''
                        
                        # 添加使用者名稱
                        if self.data_provider and hasattr(self.data_provider, 'user_mapper'):
                            user_name = self.data_provider.user_mapper.get_user_name(record.get('user_id', 0))
                            enhanced_record['user_name'] = user_name
                        else:
                            enhanced_record['user_name'] = f"使用者{record.get('user_id', 0)}號"
                        
                        enhanced_history.append(enhanced_record)
                    
                    return jsonify({
                        'success': True,
                        'data': enhanced_history,
                        'count': len(enhanced_history)
                    })
                else:
                    return jsonify({
                        'success': False,
                        'error': '數據庫未初始化'
                    }), 500
            except Exception as e:
                logger.error(f"獲取歷史數據錯誤: {e}")
                return jsonify({
                    'success': False,
                    'error': str(e)
                }), 500
        
        @self.app.route('/api/users', methods=['GET'])
        def get_users():
            """獲取使用者列表"""
            try:
                if self.data_provider and hasattr(self.data_provider, 'user_mapper'):
                    users = self.data_provider.user_mapper.get_all_users()
                    return jsonify({
                        'success': True,
                        'data': users
                    })
                else:
                    return jsonify({
                        'success': False,
                        'error': '使用者映射未初始化'
                    }), 500
            except Exception as e:
                logger.error(f"獲取使用者列表錯誤: {e}")
                return jsonify({
                    'success': False,
                    'error': str(e)
                }), 500
        
        @self.app.route('/api/current_data', methods=['GET'])
        def get_current_data():
            """獲取當前感測器數據（待機模式）"""
            try:
                if self.current_status['mode'] == 'standby' and self.current_status['data']:
                    return jsonify({
                        'success': True,
                        'data': self.current_status['data']
                    })
                else:
                    return jsonify({
                        'success': True,
                        'data': None,
                        'message': '當前不在待機模式或無數據'
                    })
            except Exception as e:
                logger.error(f"獲取當前數據錯誤: {e}")
                return jsonify({
                    'success': False,
                    'error': str(e)
                }), 500
        
        @self.app.route('/api/health', methods=['GET'])
        def health_check():
            """健康檢查"""
            return jsonify({
                'success': True,
                'message': 'API服務正常運行'
            })
    
    def set_data_provider(self, data_provider: Any):
        """
        設置數據提供者
        
        Args:
            data_provider: 數據提供者物件（包含user_mapper等）
        """
        self.data_provider = data_provider
    
    def set_database(self, database: Any):
        """
        設置數據庫
        
        Args:
            database: 數據庫物件
        """
        self.database = database
    
    def update_status(self, mode: str, data: Optional[Dict] = None):
        """
        更新當前狀態
        
        Args:
            mode: 模式名稱
            data: 狀態數據
        """
        self.current_status = {
            'mode': mode,
            'data': data
        }
    
    def start(self):
        """啟動API服務器（在獨立線程中）"""
        if self.running:
            logger.warning("API服務器已在運行")
            return
        
        self.running = True
        self.server_thread = threading.Thread(
            target=self._run_server,
            daemon=True
        )
        self.server_thread.start()
        logger.info(f"API服務器已啟動: http://{self.host}:{self.port}")
    
    def _run_server(self):
        """運行服務器"""
        try:
            self.app.run(
                host=self.host,
                port=self.port,
                debug=False,
                use_reloader=False,
                threaded=True
            )
        except Exception as e:
            logger.error(f"API服務器運行錯誤: {e}")
        finally:
            self.running = False
    
    def stop(self):
        """停止API服務器"""
        # Flask的run()方法無法直接停止，需要通過其他方式
        # 這裡只是標記為停止，實際需要重啟應用程式才能完全停止
        self.running = False
        logger.info("API服務器已停止")

