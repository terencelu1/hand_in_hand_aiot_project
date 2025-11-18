#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
主程式入口
初始化所有模組並啟動系統
"""

import sys
import json
import logging
from pathlib import Path
from PyQt6.QtWidgets import QApplication

# 添加專案根目錄到Python路徑
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from code.serial_communicator import BMduinoCommunicator
from code.database import Database
from code.user_mapper import UserMapper
from code.cv_medication_detector import MedicationDetector
from program.state_machine import StateMachine
from program.api_server import APIServer
from program.main_ui import MainUI


def setup_logging():
    """設置日誌"""
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler('data/system.log', encoding='utf-8'),
            logging.StreamHandler(sys.stdout)
        ]
    )


def load_config(config_path: str = "data/config.json") -> dict:
    """
    載入配置檔案
    
    Args:
        config_path: 配置檔案路徑
    
    Returns:
        配置字典
    """
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
        logging.info(f"載入配置檔案: {config_path}")
        return config
    except FileNotFoundError:
        logging.error(f"配置檔案不存在: {config_path}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        logging.error(f"配置檔案格式錯誤: {e}")
        sys.exit(1)


def main():
    """主函數"""
    # 設置日誌
    setup_logging()
    logger = logging.getLogger(__name__)
    logger.info("=" * 50)
    logger.info("智慧藥盒系統啟動")
    logger.info("=" * 50)
    
    # 載入配置
    config = load_config()
    
    # 初始化數據庫
    db_path = Path("data/database.db")
    db_path.parent.mkdir(parents=True, exist_ok=True)
    database = Database(str(db_path))
    logger.info("數據庫初始化完成")
    
    # 初始化使用者映射
    user_mapper = UserMapper("data/user_config.json")
    logger.info("使用者映射初始化完成")
    
    # 初始化串口通訊
    serial_config = config.get('serial', {})
    communicator = BMduinoCommunicator(
        port=serial_config.get('port', '/dev/ttyACM0'),
        baudrate=serial_config.get('baudrate', 115200)
    )
    
    # 連接串口
    if not communicator.connect():
        logger.error("無法連接BMduino，請檢查連接")
        # 不退出，繼續運行（可能稍後會自動重連）
    
    # 初始化電腦視覺檢測
    camera_config = config.get('camera', {})
    medication_config = config.get('medication_detection', {})
    medication_detector = MedicationDetector(
        camera_id=camera_config.get('device_id', 0),
        width=camera_config.get('width', 640),
        height=camera_config.get('height', 480),
        sensitivity=medication_config.get('sensitivity', 0.7),
        timeout=medication_config.get('timeout', 30)
    )
    logger.info("電腦視覺檢測初始化完成")
    
    # 初始化狀態機
    state_machine = StateMachine()
    logger.info("狀態機初始化完成")
    
    # 初始化API服務器
    api_config = config.get('api', {})
    api_server = APIServer(
        host=api_config.get('host', '0.0.0.0'),
        port=api_config.get('port', 5000)
    )
    api_server.set_database(database)
    api_server.set_data_provider(type('DataProvider', (), {
        'user_mapper': user_mapper
    })())
    
    # 註冊數據回調到API服務器
    def update_api_status(mode: str, data: dict = None):
        api_server.update_status(mode, data)
    
    communicator.register_callback('standby', lambda d: update_api_status('standby', d))
    communicator.register_callback('working_start', lambda: update_api_status('working'))
    communicator.register_callback('working_final', lambda d: update_api_status('working_final', d))
    
    # 註冊數據儲存回調
    def save_measurement(data: dict):
        fingerprint_id = data.get('fingerprint_id')
        if fingerprint_id:
            database.insert_measurement(
                user_id=fingerprint_id,
                object_temp=data.get('object_temp'),
                ambient_temp=data.get('ambient_temp'),
                heart_rate=data.get('heart_rate'),
                spo2=data.get('spo2')
            )
    
    communicator.register_callback('working_final', save_measurement)
    
    # 啟動API服務器
    api_server.start()
    logger.info("API服務器已啟動")
    
    # 啟動串口監聽
    communicator.start_listening()
    logger.info("串口監聽已啟動")
    
    # 創建Qt應用程式
    app = QApplication(sys.argv)
    
    # 設置應用程式字體（支援繁體中文）
    app.setFont(app.font())  # 使用系統預設字體
    
    # 創建主UI
    main_ui = MainUI(
        state_machine=state_machine,
        communicator=communicator,
        user_mapper=user_mapper,
        medication_detector=medication_detector,
        config=config
    )
    
    main_ui.show()
    logger.info("UI界面已顯示")
    
    try:
        # 運行應用程式
        sys.exit(app.exec())
    except KeyboardInterrupt:
        logger.info("收到中斷信號，正在關閉...")
    finally:
        # 清理資源
        logger.info("正在清理資源...")
        communicator.stop_listening()
        communicator.disconnect()
        medication_detector.stop_detection()
        api_server.stop()
        database.close()
        logger.info("系統已關閉")


if __name__ == "__main__":
    main()

