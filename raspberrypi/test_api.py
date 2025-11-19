#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
API測試腳本
用於測試樹莓派API服務器是否正常運作
可以在電腦上運行，只要電腦和樹莓派在同一個Wi-Fi網絡中
"""

import requests
import json
import sys
from typing import Optional


class APITester:
    """API測試類別"""
    
    def __init__(self, base_url: str = "http://192.168.1.100:5000"):
        """
        初始化測試器
        
        Args:
            base_url: API服務器基礎URL（預設為 http://192.168.1.100:5000）
                      請根據實際樹莓派IP地址修改
        """
        self.base_url = base_url.rstrip('/')
        self.session = requests.Session()
        self.session.timeout = 5  # 5秒超時
    
    def test_health(self) -> bool:
        """測試健康檢查端點"""
        print("\n" + "="*50)
        print("測試 1: 健康檢查 (/api/health)")
        print("="*50)
        try:
            response = self.session.get(f"{self.base_url}/api/health")
            print(f"狀態碼: {response.status_code}")
            print(f"回應內容: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
            return response.status_code == 200
        except requests.exceptions.ConnectionError:
            print("❌ 連接失敗！請確認：")
            print("   1. 樹莓派是否已啟動並運行主程式")
            print("   2. 樹莓派IP地址是否正確")
            print("   3. 電腦和樹莓派是否在同一個Wi-Fi網絡中")
            print("   4. 防火牆是否阻擋了連接")
            return False
        except requests.exceptions.Timeout:
            print("❌ 請求超時！")
            return False
        except Exception as e:
            print(f"❌ 錯誤: {e}")
            return False
    
    def test_status(self) -> bool:
        """測試狀態端點"""
        print("\n" + "="*50)
        print("測試 2: 獲取系統狀態 (/api/status)")
        print("="*50)
        try:
            response = self.session.get(f"{self.base_url}/api/status")
            print(f"狀態碼: {response.status_code}")
            data = response.json()
            print(f"回應內容: {json.dumps(data, indent=2, ensure_ascii=False)}")
            return response.status_code == 200
        except Exception as e:
            print(f"❌ 錯誤: {e}")
            return False
    
    def test_users(self) -> bool:
        """測試使用者列表端點"""
        print("\n" + "="*50)
        print("測試 3: 獲取使用者列表 (/api/users)")
        print("="*50)
        try:
            response = self.session.get(f"{self.base_url}/api/users")
            print(f"狀態碼: {response.status_code}")
            data = response.json()
            print(f"回應內容: {json.dumps(data, indent=2, ensure_ascii=False)}")
            return response.status_code == 200
        except Exception as e:
            print(f"❌ 錯誤: {e}")
            return False
    
    def test_current_data(self) -> bool:
        """測試當前數據端點"""
        print("\n" + "="*50)
        print("測試 4: 獲取當前感測器數據 (/api/current_data)")
        print("="*50)
        try:
            response = self.session.get(f"{self.base_url}/api/current_data")
            print(f"狀態碼: {response.status_code}")
            data = response.json()
            print(f"回應內容: {json.dumps(data, indent=2, ensure_ascii=False)}")
            return response.status_code == 200
        except Exception as e:
            print(f"❌ 錯誤: {e}")
            return False
    
    def test_latest(self, user_id: int = 1) -> bool:
        """測試最新數據端點"""
        print("\n" + "="*50)
        print(f"測試 5: 獲取最新測量數據 (/api/latest?user_id={user_id})")
        print("="*50)
        try:
            response = self.session.get(
                f"{self.base_url}/api/latest",
                params={'user_id': user_id}
            )
            print(f"狀態碼: {response.status_code}")
            data = response.json()
            print(f"回應內容: {json.dumps(data, indent=2, ensure_ascii=False)}")
            return response.status_code == 200
        except Exception as e:
            print(f"❌ 錯誤: {e}")
            return False
    
    def test_history(self, user_id: int = 1, limit: int = 10) -> bool:
        """測試歷史數據端點"""
        print("\n" + "="*50)
        print(f"測試 6: 獲取歷史數據 (/api/history?user_id={user_id}&limit={limit})")
        print("="*50)
        try:
            response = self.session.get(
                f"{self.base_url}/api/history",
                params={'user_id': user_id, 'limit': limit}
            )
            print(f"狀態碼: {response.status_code}")
            data = response.json()
            print(f"回應內容: {json.dumps(data, indent=2, ensure_ascii=False)}")
            return response.status_code == 200
        except Exception as e:
            print(f"❌ 錯誤: {e}")
            return False
    
    def run_all_tests(self):
        """運行所有測試"""
        print("\n" + "="*70)
        print("開始測試樹莓派API服務器")
        print("="*70)
        print(f"API服務器地址: {self.base_url}")
        print("\n提示：如果連接失敗，請確認樹莓派IP地址是否正確")
        print("可以在樹莓派上運行 'hostname -I' 或 'ip addr' 查看IP地址")
        
        results = []
        
        # 測試健康檢查（必須先通過）
        if not self.test_health():
            print("\n" + "="*70)
            print("❌ 健康檢查失敗！請先確認API服務器是否正常運行")
            print("="*70)
            return
        
        results.append(("健康檢查", True))
        results.append(("系統狀態", self.test_status()))
        results.append(("使用者列表", self.test_users()))
        results.append(("當前數據", self.test_current_data()))
        results.append(("最新數據", self.test_latest(1)))
        results.append(("歷史數據", self.test_history(1, 10)))
        
        # 顯示測試結果摘要
        print("\n" + "="*70)
        print("測試結果摘要")
        print("="*70)
        passed = sum(1 for _, result in results if result)
        total = len(results)
        
        for test_name, result in results:
            status = "✅ 通過" if result else "❌ 失敗"
            print(f"{test_name}: {status}")
        
        print(f"\n總計: {passed}/{total} 測試通過")
        print("="*70)


def main():
    """主函數"""
    # 預設IP地址，可以通過命令行參數修改
    base_url = "http://192.168.1.100:5000"
    
    if len(sys.argv) > 1:
        base_url = sys.argv[1]
        if not base_url.startswith("http://"):
            base_url = f"http://{base_url}"
        if not base_url.endswith(":5000"):
            base_url = f"{base_url}:5000"
    
    print("\n使用說明：")
    print("  python3 test_api.py                    # 使用預設IP (192.168.1.100)")
    print("  python3 test_api.py 192.168.1.101     # 指定樹莓派IP地址")
    print("  python3 test_api.py http://192.168.1.101:5000  # 完整URL")
    print()
    
    tester = APITester(base_url)
    tester.run_all_tests()


if __name__ == "__main__":
    main()

