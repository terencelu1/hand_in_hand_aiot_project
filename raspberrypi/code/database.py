#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
數據庫模組
負責數據的儲存和查詢
"""

import sqlite3
import json
from datetime import datetime
from typing import List, Dict, Optional
from pathlib import Path
import logging

logger = logging.getLogger(__name__)


class Database:
    """數據庫操作類別"""
    
    def __init__(self, db_path: str = "data/database.db"):
        """
        初始化數據庫
        
        Args:
            db_path: 數據庫檔案路徑
        """
        # 確保目錄存在
        db_file = Path(db_path)
        db_file.parent.mkdir(parents=True, exist_ok=True)
        
        self.db_path = db_path
        self.conn: Optional[sqlite3.Connection] = None
        self._init_database()
    
    def _init_database(self):
        """初始化數據庫表結構"""
        try:
            self.conn = sqlite3.connect(self.db_path, check_same_thread=False)
            self.conn.row_factory = sqlite3.Row  # 使用字典式訪問
            
            cursor = self.conn.cursor()
            
            # 創建測量記錄表
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS measurements (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp DATETIME NOT NULL,
                    user_id INTEGER NOT NULL,
                    object_temp REAL,
                    ambient_temp REAL,
                    heart_rate INTEGER,
                    spo2 INTEGER
                )
            ''')
            
            # 創建索引以提高查詢效率
            cursor.execute('''
                CREATE INDEX IF NOT EXISTS idx_timestamp ON measurements(timestamp)
            ''')
            
            cursor.execute('''
                CREATE INDEX IF NOT EXISTS idx_user_id ON measurements(user_id)
            ''')
            
            self.conn.commit()
            logger.info("數據庫初始化完成")
            
        except sqlite3.Error as e:
            logger.error(f"數據庫初始化失敗: {e}")
            raise
    
    def insert_measurement(self, user_id: int, object_temp: float = None,
                          ambient_temp: float = None, heart_rate: int = None,
                          spo2: int = None) -> bool:
        """
        插入測量記錄
        
        Args:
            user_id: 使用者ID
            object_temp: 物體溫度
            ambient_temp: 環境溫度
            heart_rate: 心率
            spo2: 血氧
        
        Returns:
            是否插入成功
        """
        try:
            cursor = self.conn.cursor()
            cursor.execute('''
                INSERT INTO measurements 
                (timestamp, user_id, object_temp, ambient_temp, heart_rate, spo2)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (
                datetime.now().isoformat(),
                user_id,
                object_temp,
                ambient_temp,
                heart_rate,
                spo2
            ))
            self.conn.commit()
            logger.debug(f"插入測量記錄: 使用者{user_id}")
            return True
        except sqlite3.Error as e:
            logger.error(f"插入測量記錄失敗: {e}")
            return False
    
    def get_latest_measurement(self, user_id: Optional[int] = None) -> Optional[Dict]:
        """
        獲取最新的測量記錄
        
        Args:
            user_id: 使用者ID，None表示所有使用者
        
        Returns:
            最新的測量記錄字典，失敗返回None
        """
        try:
            cursor = self.conn.cursor()
            
            if user_id:
                cursor.execute('''
                    SELECT * FROM measurements
                    WHERE user_id = ?
                    ORDER BY timestamp DESC
                    LIMIT 1
                ''', (user_id,))
            else:
                cursor.execute('''
                    SELECT * FROM measurements
                    ORDER BY timestamp DESC
                    LIMIT 1
                ''')
            
            row = cursor.fetchone()
            if row:
                return dict(row)
            return None
        except sqlite3.Error as e:
            logger.error(f"查詢最新記錄失敗: {e}")
            return None
    
    def get_history(self, user_id: Optional[int] = None, limit: int = 100) -> List[Dict]:
        """
        獲取歷史記錄
        
        Args:
            user_id: 使用者ID，None表示所有使用者
            limit: 返回記錄數量限制
        
        Returns:
            歷史記錄列表
        """
        try:
            cursor = self.conn.cursor()
            
            if user_id:
                cursor.execute('''
                    SELECT * FROM measurements
                    WHERE user_id = ?
                    ORDER BY timestamp DESC
                    LIMIT ?
                ''', (user_id, limit))
            else:
                cursor.execute('''
                    SELECT * FROM measurements
                    ORDER BY timestamp DESC
                    LIMIT ?
                ''', (limit,))
            
            rows = cursor.fetchall()
            return [dict(row) for row in rows]
        except sqlite3.Error as e:
            logger.error(f"查詢歷史記錄失敗: {e}")
            return []
    
    def get_user_statistics(self, user_id: int, days: int = 30) -> Dict:
        """
        獲取使用者統計數據
        
        Args:
            user_id: 使用者ID
            days: 統計天數
        
        Returns:
            統計數據字典
        """
        try:
            cursor = self.conn.cursor()
            
            # 計算日期範圍
            from_date = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
            from_date = from_date.replace(day=from_date.day - days)
            
            # 總記錄數
            cursor.execute('''
                SELECT COUNT(*) as count FROM measurements
                WHERE user_id = ? AND timestamp >= ?
            ''', (user_id, from_date.isoformat()))
            total_count = cursor.fetchone()['count']
            
            # 平均心率
            cursor.execute('''
                SELECT AVG(heart_rate) as avg_hr FROM measurements
                WHERE user_id = ? AND timestamp >= ? AND heart_rate IS NOT NULL
            ''', (user_id, from_date.isoformat()))
            avg_hr_row = cursor.fetchone()
            avg_heart_rate = round(avg_hr_row['avg_hr'], 1) if avg_hr_row['avg_hr'] else None
            
            # 平均血氧
            cursor.execute('''
                SELECT AVG(spo2) as avg_spo2 FROM measurements
                WHERE user_id = ? AND timestamp >= ? AND spo2 IS NOT NULL
            ''', (user_id, from_date.isoformat()))
            avg_spo2_row = cursor.fetchone()
            avg_spo2 = round(avg_spo2_row['avg_spo2'], 1) if avg_spo2_row['avg_spo2'] else None
            
            return {
                'user_id': user_id,
                'total_count': total_count,
                'avg_heart_rate': avg_heart_rate,
                'avg_spo2': avg_spo2,
                'days': days
            }
        except sqlite3.Error as e:
            logger.error(f"查詢統計數據失敗: {e}")
            return {}
    
    def close(self):
        """關閉數據庫連接"""
        if self.conn:
            self.conn.close()
            logger.info("數據庫連接已關閉")
    
    def __del__(self):
        """析構函數"""
        self.close()

