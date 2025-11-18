#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
BMduino 整合程式測試腳本
用於測試三個模式是否正常運作
"""

import serial
import serial.tools.list_ports
import time
import threading
import sys
from datetime import datetime

class BMduinoTester:
    def __init__(self, port=None, baudrate=115200):
        self.port = port
        self.baudrate = baudrate
        self.ser = None
        self.running = False
        self.received_data = []
        
    def list_ports(self):
        """列出所有可用的串口"""
        ports = serial.tools.list_ports.comports()
        print("\n可用的串口：")
        for i, port in enumerate(ports):
            print(f"  {i+1}. {port.device} - {port.description}")
        return ports
    
    def connect(self):
        """連接到 BMduino"""
        if self.port is None:
            ports = self.list_ports()
            if len(ports) == 0:
                print("錯誤：未找到可用串口！")
                return False
            
            print("\n請輸入串口號碼（例如：COM3）或按 Enter 使用第一個：")
            user_input = input().strip()
            if user_input:
                self.port = user_input
            else:
                self.port = ports[0].device
        
        try:
            self.ser = serial.Serial(
                self.port,
                self.baudrate,
                timeout=1
            )
            print(f"\n✓ 已連接到 {self.port}，波特率：{self.baudrate}")
            time.sleep(2)  # 等待連接穩定
            return True
        except serial.SerialException as e:
            print(f"錯誤：無法打開串口 {self.port}")
            print(f"詳細信息：{e}")
            return False
    
    def disconnect(self):
        """斷開連接"""
        if self.ser and self.ser.is_open:
            self.ser.close()
            print("\n✓ 已斷開連接")
    
    def read_data(self):
        """讀取數據（在背景執行）"""
        while self.running:
            try:
                if self.ser and self.ser.in_waiting > 0:
                    line = self.ser.readline().decode('utf-8', errors='ignore').strip()
                    if line:
                        timestamp = datetime.now().strftime('%H:%M:%S')
                        self.received_data.append((timestamp, line))
                        print(f"[{timestamp}] {line}")
            except Exception as e:
                if self.running:
                    print(f"讀取錯誤：{e}")
            time.sleep(0.01)
    
    def send_command(self, command):
        """發送命令"""
        if self.ser and self.ser.is_open:
            try:
                self.ser.write((command + '\n').encode('utf-8'))
                print(f"→ 發送命令：{command}")
                return True
            except Exception as e:
                print(f"發送錯誤：{e}")
                return False
        return False
    
    def start_monitoring(self):
        """開始監聽數據"""
        self.running = True
        self.read_thread = threading.Thread(target=self.read_data, daemon=True)
        self.read_thread.start()
        print("\n✓ 開始監聽數據...")
    
    def stop_monitoring(self):
        """停止監聽"""
        self.running = False
        if hasattr(self, 'read_thread'):
            self.read_thread.join(timeout=1)
        print("✓ 停止監聽")
    
    def test_standby_mode(self, duration=10):
        """測試待機模式"""
        print("\n" + "="*50)
        print("測試 1：待機模式")
        print("="*50)
        print(f"監聽 {duration} 秒，觀察待機模式輸出...")
        print("預期格式：STANDBY,物體溫度,環境溫度,心率,血氧")
        print("-"*50)
        
        time.sleep(duration)
        
        # 分析接收到的數據
        standby_data = [d for _, d in self.received_data if d.startswith("STANDBY")]
        if standby_data:
            print(f"\n✓ 待機模式正常，收到 {len(standby_data)} 條數據")
            print(f"  範例：{standby_data[-1]}")
        else:
            print("\n✗ 未收到待機模式數據")
    
    def test_working_mode(self):
        """測試工作模式（需要手動觸發指紋辨識）"""
        print("\n" + "="*50)
        print("測試 2：工作模式")
        print("="*50)
        print("請將手指放在指紋辨識器上觸發工作模式...")
        print("然後將手指放在 MAX30102 上測量")
        print("預期輸出：")
        print("  - WORKING,START (進入工作模式)")
        print("  - WORKING,物體溫度,環境溫度,心率,血氧 (數據穩定後)")
        print("  - 或 WORKING,NO_DATA / WORKING,TIMEOUT (錯誤情況)")
        print("-"*50)
        print("等待 20 秒或按 Enter 繼續...")
        
        start_time = time.time()
        
        # 使用背景線程處理輸入
        input_received = threading.Event()
        def wait_input():
            try:
                input()
                input_received.set()
            except:
                pass
        
        input_thread = threading.Thread(target=wait_input, daemon=True)
        input_thread.start()
        
        while time.time() - start_time < 20:
            if input_received.is_set():
                break
            time.sleep(0.1)
        
        # 分析接收到的數據
        working_data = [d for _, d in self.received_data if d.startswith("WORKING")]
        if working_data:
            print(f"\n✓ 工作模式觸發，收到 {len(working_data)} 條數據")
            for data in working_data:
                print(f"  - {data}")
        else:
            print("\n⚠ 未收到工作模式數據（可能未觸發指紋辨識）")
    
    def test_receive_mode(self):
        """測試接收模式（繼電器控制）"""
        print("\n" + "="*50)
        print("測試 3：接收模式（繼電器控制）")
        print("="*50)
        
        for relay_num in range(1, 5):
            print(f"\n測試繼電器 {relay_num}...")
            self.send_command(f"RELAY,{relay_num}")
            time.sleep(2)  # 等待回應
            
            # 檢查回應
            recent_data = [d for _, d in self.received_data[-5:] if "RELAY" in d]
            if recent_data:
                print(f"  回應：{recent_data[-1]}")
            else:
                print("  ⚠ 未收到回應")
        
        # 測試錯誤命令
        print("\n測試錯誤命令...")
        self.send_command("RELAY,5")  # 無效的繼電器號碼
        time.sleep(1)
        
        self.send_command("INVALID")  # 無效的命令
        time.sleep(1)
        
        print("\n✓ 接收模式測試完成")
    
    def show_statistics(self):
        """顯示統計信息"""
        print("\n" + "="*50)
        print("統計信息")
        print("="*50)
        print(f"總共收到 {len(self.received_data)} 條數據")
        
        standby_count = len([d for _, d in self.received_data if d.startswith("STANDBY")])
        working_count = len([d for _, d in self.received_data if d.startswith("WORKING")])
        relay_count = len([d for _, d in self.received_data if "RELAY" in d])
        mode_count = len([d for _, d in self.received_data if d.startswith("MODE")])
        
        print(f"  待機模式數據：{standby_count} 條")
        print(f"  工作模式數據：{working_count} 條")
        print(f"  繼電器相關：{relay_count} 條")
        print(f"  模式切換：{mode_count} 條")
        
        if self.received_data:
            print("\n最後 10 條數據：")
            for timestamp, data in self.received_data[-10:]:
                print(f"  [{timestamp}] {data}")

def main():
    print("="*50)
    print("BMduino 整合程式測試工具")
    print("="*50)
    
    tester = BMduinoTester()
    
    # 連接
    if not tester.connect():
        return
    
    try:
        # 開始監聽
        tester.start_monitoring()
        
        # 等待初始化
        print("\n等待系統初始化...")
        time.sleep(3)
        
        # 執行測試
        while True:
            print("\n" + "="*50)
            print("請選擇測試項目：")
            print("  1. 測試待機模式（監聽 10 秒）")
            print("  2. 測試工作模式（需要觸發指紋辨識）")
            print("  3. 測試接收模式（繼電器控制）")
            print("  4. 顯示統計信息")
            print("  5. 完整測試（所有項目）")
            print("  0. 退出")
            print("-"*50)
            
            choice = input("請輸入選項 (0-5): ").strip()
            
            if choice == '0':
                break
            elif choice == '1':
                tester.test_standby_mode(10)
            elif choice == '2':
                tester.test_working_mode()
            elif choice == '3':
                tester.test_receive_mode()
            elif choice == '4':
                tester.show_statistics()
            elif choice == '5':
                tester.test_standby_mode(5)
                tester.test_working_mode()
                tester.test_receive_mode()
                tester.show_statistics()
            else:
                print("無效選項，請重新選擇")
            
            time.sleep(1)
    
    except KeyboardInterrupt:
        print("\n\n用戶中斷")
    except Exception as e:
        print(f"\n錯誤：{e}")
    finally:
        tester.stop_monitoring()
        tester.disconnect()
        print("\n測試結束")

if __name__ == "__main__":
    main()

