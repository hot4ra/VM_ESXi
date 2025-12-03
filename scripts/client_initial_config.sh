#!/bin/bash
# client_initial_config.sh: 客戶端 fstab 初始掛載腳本

# 請根據您的環境修改以下變數
SERVER_IP="192.168.8.40"
SHARE_PATH="/home/ubn/Shared"
MOUNT_POINT="/mnt/getshare"

FSTAB_CONFIG="${SERVER_IP}:${SHARE_PATH} ${MOUNT_POINT} nfs defaults,ro,hard,intr,noatime,x-systemd.automount 0 0"

# --- 階段三：初始掛載配置 ---
echo "--- 1/2: 測試掛載並寫入 fstab ---"

# 測試掛載
sudo mount ${SERVER_IP}:${SHARE_PATH} ${MOUNT_POINT}

# 寫入 fstab 配置
echo "${FSTAB_CONFIG}" | sudo tee -a /etc/fstab > /dev/null

# 卸載測試掛載 (準備讓 mount -a 重新載入)
sudo umount ${MOUNT_POINT}

# 重新載入 fstab 配置並驗證
echo "--- 2/2: 重新載入配置並驗證 ---"
sudo mount -a

# 驗證掛載是否成功
if mount | grep "${MOUNT_POINT}"; then
    echo "掛載成功！驗證檔案..."
    ls -l ${MOUNT_POINT}
else
    echo "錯誤：NFS 掛載失敗，請檢查網路和伺服器 IP/exports 配置。"
fi

echo "--- 客戶端配置完成。 ---"
