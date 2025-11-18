#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
BMduino 整合程式簡單測試腳本
簡化版本，直接監聽和測試
"""

import serial
import serial.tools.list_ports
import time
import threading
import queue

def list_ports():
    """列出所有可用的串口"""
    ports = serial.tools.list_ports.comports()
    print("\n可用的串口：")
    for i, port in enumerate(ports):
        print(f"  {i+1}. {port.device} - {port.description}")
    return ports

def main():
    print("="*50)
    print("BMduino 整合程式簡單測試")
    print("="*50)
    
    # 選擇串口
    ports = list_ports()
    if len(ports) == 0:
        print("錯誤：未找到可用串口！")
        return
    
    print("\n請輸入串口號碼（例如：COM3）或按 Enter 使用第一個：")
    user_input = input().strip()
    if user_input:
        port_name = user_input
    else:
        port_name = ports[0].device
    
    # 使用背景線程處理輸入
    input_queue = queue.Queue()
    
    def input_thread():
        while True:
            try:
                command = input().strip()
                if command:
                    input_queue.put(command)
            except:
                break
    
    input_thread_obj = threading.Thread(target=input_thread, daemon=True)
    input_thread_obj.start()
    
    # 連接和監聽
    try:
        ser = serial.Serial(port_name, 115200, timeout=1)
        print(f"\n✓ 已連接到 {port_name}")
        print("開始監聽數據...")
        print("輸入命令：RELAY,1 到 RELAY,4（控制繼電器）")
        print("輸入 quit 或 exit 退出")
        print("="*50)
        time.sleep(2)  # 等待連接穩定
        
        while True:
            # 讀取串口數據
            if ser.in_waiting > 0:
                line = ser.readline().decode('utf-8', errors='ignore').strip()
                if line:
                    timestamp = time.strftime('%H:%M:%S')
                    print(f"[{timestamp}] {line}")
            
            # 處理輸入命令
            try:
                command = input_queue.get_nowait()
                if command.startswith("RELAY,"):
                    ser.write((command + '\n').encode('utf-8'))
                    print(f"→ 發送：{command}")
                elif command == "quit" or command == "exit":
                    break
                else:
                    print("可用命令：")
                    print("  RELAY,1 到 RELAY,4 - 控制繼電器")
                    print("  quit 或 exit - 退出")
            except queue.Empty:
                pass
            
            time.sleep(0.01)
    
    except serial.SerialException as e:
        print(f"錯誤：無法打開串口 {port_name}")
        print(f"詳細信息：{e}")
    except KeyboardInterrupt:
        print("\n\n停止監聽")
    except Exception as e:
        print(f"錯誤：{e}")
    finally:
        if 'ser' in locals() and ser.is_open:
            ser.close()
            print("已斷開連接")

if __name__ == "__main__":
    main()
