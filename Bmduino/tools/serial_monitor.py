"""
Windows USB 串口監視工具
用於測試 BMduino native 連接
"""

import serial
import serial.tools.list_ports
import sys
import time

def list_ports():
    """列出所有可用的串口"""
    ports = serial.tools.list_ports.comports()
    print("可用的串口：")
    for i, port in enumerate(ports):
        print(f"  {i+1}. {port.device} - {port.description}")
    return ports

def monitor_serial(port_name, baudrate=115200):
    """監視串口輸出"""
    try:
        ser = serial.Serial(port_name, baudrate, timeout=1)
        print(f"\n已連接到 {port_name}，波特率：{baudrate}")
        print("開始監視串口輸出（按 Ctrl+C 停止）...\n")
        print("=" * 50)
        
        while True:
            if ser.in_waiting > 0:
                line = ser.readline().decode('utf-8', errors='ignore').strip()
                if line:
                    print(f"[{time.strftime('%H:%M:%S')}] {line}")
            time.sleep(0.01)
            
    except serial.SerialException as e:
        print(f"錯誤：無法打開串口 {port_name}")
        print(f"詳細信息：{e}")
    except KeyboardInterrupt:
        print("\n\n停止監視")
    finally:
        if 'ser' in locals() and ser.is_open:
            ser.close()
            print("串口已關閉")

if __name__ == "__main__":
    print("BMduino USB 串口監視工具")
    print("=" * 50)
    
    # 列出可用串口
    ports = list_ports()
    
    if len(ports) == 0:
        print("未找到可用串口！")
        sys.exit(1)
    
    # 讓用戶選擇串口
    if len(sys.argv) > 1:
        port_name = sys.argv[1]
    else:
        print("\n請輸入串口號碼（例如：COM3）或按 Enter 使用第一個：")
        user_input = input().strip()
        
        if user_input:
            port_name = user_input
        else:
            port_name = ports[0].device
    
    # 設定波特率
    baudrate = 115200
    if len(sys.argv) > 2:
        baudrate = int(sys.argv[2])
    
    # 開始監視
    monitor_serial(port_name, baudrate)

