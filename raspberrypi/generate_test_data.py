#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
生成測試數據腳本
從11/10到11/18，每12小時一筆數據，使用者1-4都有數據
"""

import sys
from pathlib import Path
from datetime import datetime, timedelta
import random

# 添加專案根目錄到Python路徑
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

from code.database import Database


def generate_test_data():
    """生成測試數據"""
    # 初始化數據庫
    db_path = Path("data/database.db")
    database = Database(str(db_path))
    
    # 設定時間範圍：從2025-11-10 00:00:00開始，到2025-11-18 23:59:59結束
    start_date = datetime(2025, 11, 10, 0, 0, 0)
    end_date = datetime(2025, 11, 18, 23, 59, 59)
    
    # 每12小時一筆數據
    time_interval = timedelta(hours=12)
    
    # 使用者列表
    users = [1, 2, 3, 4]
    
    # 數據範圍
    heart_rate_min = 70
    heart_rate_max = 110
    spo2_min = 85
    spo2_max = 95
    temp_min = 23.0
    temp_max = 26.0
    
    print("開始生成測試數據...")
    print(f"時間範圍: {start_date.strftime('%Y-%m-%d %H:%M:%S')} 到 {end_date.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"時間間隔: 每12小時")
    print(f"使用者: {users}")
    print()
    
    total_count = 0
    
    # 為每個使用者生成數據
    for user_id in users:
        print(f"正在為使用者{user_id}生成數據...")
        user_count = 0
        
        # 從開始時間開始，每12小時生成一筆數據
        current_time = start_date
        while current_time <= end_date:
            # 生成隨機數據
            heart_rate = random.randint(heart_rate_min, heart_rate_max)
            spo2 = random.randint(spo2_min, spo2_max)
            object_temp = round(random.uniform(temp_min, temp_max), 2)
            ambient_temp = round(random.uniform(temp_min, temp_max), 2)
            
            # 插入數據（使用指定的時間戳）
            # 注意：這裡需要修改數據庫的insert_measurement方法來支持指定時間
            # 或者直接使用SQL插入
            try:
                cursor = database.conn.cursor()
                cursor.execute('''
                    INSERT INTO measurements 
                    (timestamp, user_id, object_temp, ambient_temp, heart_rate, spo2)
                    VALUES (?, ?, ?, ?, ?, ?)
                ''', (
                    current_time.isoformat(),
                    user_id,
                    object_temp,
                    ambient_temp,
                    heart_rate,
                    spo2
                ))
                database.conn.commit()
                user_count += 1
                total_count += 1
                
                if user_count % 5 == 0:
                    print(f"  已生成 {user_count} 筆數據...")
            except Exception as e:
                print(f"  插入數據失敗: {e}")
            
            # 移動到下一個時間點
            current_time += time_interval
        
        print(f"使用者{user_id}完成，共生成 {user_count} 筆數據")
        print()
    
    print("=" * 50)
    print(f"測試數據生成完成！")
    print(f"總共生成 {total_count} 筆數據")
    print(f"每個使用者約 {total_count // len(users)} 筆數據")
    print("=" * 50)
    
    # 驗證數據
    print("\n驗證數據...")
    for user_id in users:
        history = database.get_history(user_id, limit=1000)
        print(f"使用者{user_id}: {len(history)} 筆記錄")
        if len(history) > 0:
            latest = history[0]
            oldest = history[-1]
            print(f"  最新: {latest['timestamp']}")
            print(f"  最早: {oldest['timestamp']}")
    
    # 關閉數據庫連接
    database.close()


if __name__ == "__main__":
    generate_test_data()

