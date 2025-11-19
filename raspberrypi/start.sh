#!/bin/bash
# 智慧藥盒系統啟動腳本

# 獲取腳本所在目錄
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 設置Python路徑（確保可以導入模組）
export PYTHONPATH="$SCRIPT_DIR:$PYTHONPATH"

# 啟動主程式
python3 program/main.py

