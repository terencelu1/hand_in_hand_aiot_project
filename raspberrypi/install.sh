#!/bin/bash
# 智慧藥盒系統安裝腳本

echo "=========================================="
echo "智慧藥盒系統安裝"
echo "=========================================="

# 檢查Python版本
python3 --version
if [ $? -ne 0 ]; then
    echo "錯誤: 未找到Python3"
    exit 1
fi

# 更新系統套件
echo "更新系統套件..."
sudo apt-get update
sudo apt-get upgrade -y

# 安裝系統依賴
echo "安裝系統依賴..."
sudo apt-get install -y \
    python3-pip \
    python3-pyqt6 \
    python3-opencv \
    libopencv-dev \
    libgl1-mesa-glx \
    libglib2.0-0

# 安裝Python套件
echo "安裝Python套件..."
pip3 install -r requirements.txt

# 設置執行權限
chmod +x start.sh
chmod +x install.sh

# 創建數據目錄
mkdir -p data
mkdir -p models

echo "=========================================="
echo "安裝完成！"
echo "=========================================="
echo "使用以下命令啟動系統:"
echo "  ./start.sh"
echo ""
echo "或使用systemd服務自動啟動（需要先設置）:"
echo "  sudo systemctl enable smart-medicine-box.service"
echo "  sudo systemctl start smart-medicine-box.service"

