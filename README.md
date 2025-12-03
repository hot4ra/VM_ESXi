# 🚀 從零開始：VM 基礎設施部署與管理指南 (單一複製模式)

# ## 🎯 階段一：VM 範本準備與通用化

# ### 1. 服務安裝、優化與清理 (Template Preparation)

# 1. 更新系統並安裝核心工具 (所有 VM 必備)
sudo apt update
sudo apt install -y openssh-server nfs-common nfs-kernel-server

# 2. 創建掛載點 (客戶端準備)
sudo mkdir -p /mnt/getshare

# 3. 編輯 journald.conf (避免硬碟佔滿)
# 執行 sudo nano /etc/systemd/journald.conf，新增或修改 SystemMaxUse=500M

# 4. 清理與通用化
sudo rm -f /etc/ssh/ssh_host_* # 移除 SSH Host Keys (最關鍵！)
sudo rm -f /etc/udev/rules.d/70-persistent-net.rules
sudo apt clean
history -c && rm -f ~/.bash_history

# 5. 製作範本 (關機)
sudo shutdown now

# ---
# ## 💾 階段二：NFS 共享服務配置 (伺服器端: 192.168.8.40)

# ### 1. 準備、匯出與啟用服務

# 1. 準備路徑與權限
sudo mkdir -p /home/ubn/Shared
sudo chown ubn:ubn /home/ubn/Shared
mv /home/ubn/run.sh /home/ubn/Shared/

# 2. 編輯 NFS 匯出配置檔案
sudo nano /etc/exports

# 3. 新增匯出規則
# /home/ubn/Shared 192.168.8.0/24(rw,sync,no_subtree_check)

# 4. 啟用服務
sudo exportfs -ra
sudo systemctl restart nfs-server

# ---
# ## 🔑 階段三：SSH 自動化與客戶端初始配置

# ### 1. SSH 金鑰設置 (實現無密碼連線)

# 1. 生成金鑰 (在 MobaXterm Local Terminal 或 管理機上執行)
ssh-keygen -t rsa -b 4096

# 2. 部署公鑰到目標 VM (針對所有客戶端和伺服器執行)
ssh-copy-id ubn@<目標VM的IP地址>

# ### 2. 客戶端 VM 初始掛載配置

# 1. 測試掛載 (確認連線)
sudo mount 192.168.8.40:/home/ubn/Shared /mnt/getshare

# 2. 設定永久掛載 (以 root 權限編輯 fstab)
sudo nano /etc/fstab

# 3. 新增配置行
# 192.168.8.40:/home/ubn/Shared /mnt/getshare nfs defaults,ro,hard,intr,noatime,x-systemd.automount 0 0

# 4. 最終驗證 (立即載入配置並檢查檔案)
sudo mount -a
ls -l /mnt/getshare
