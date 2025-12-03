#!/bin/bash
# nfs_server_setup.sh: NFS 共享服務配置腳本

SHARE_PATH="/home/ubn/Shared"
NETWORK="192.168.8.0/24"
CONFIG_LINE="${SHARE_PATH} ${NETWORK}(rw,sync,no_subtree_check)"

echo "--- 1/2: 準備路徑與權限 ---"
sudo mkdir -p ${SHARE_PATH}
sudo chown ubn:ubn ${SHARE_PATH}

# 假設 run.sh 已在用戶主目錄，移動到共享目錄
if [ -f "/home/ubn/run.sh" ]; then
    mv /home/ubn/run.sh ${SHARE_PATH}/
    echo "run.sh 已移動到共享目錄。"
else
    echo "run.sh 不存在，請手動放入 ${SHARE_PATH}。"
fi

# --- 2/2: 設定匯出與啟用服務 ---
echo "--- 2/2: 設定匯出檔案 /etc/exports ---"
echo ${CONFIG_LINE} | sudo tee -a /etc/exports > /dev/null

# 啟用服務
sudo exportfs -ra
sudo systemctl restart nfs-server

echo "--- NFS 伺服器配置完成。請確認服務狀態。 ---"
