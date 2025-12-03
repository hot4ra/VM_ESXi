# 🚀 最終部署指南：純指令配置模式 (GitHub 專用)

## 🎯 階段一：VM 範本準備與通用化

| 階段 | 主題強調 | 執行指令 | 目的與說明 |
| :--- | :--- | :--- | :--- |
| **I. 預裝服務** | **所有 VM 必備** | `sudo apt update`<br>`sudo apt install -y openssh-server nfs-common nfs-kernel-server` | |
| **II. 創建掛載點** | **客戶端準備** | `sudo mkdir -p /mnt/getshare` | |
| **III. 日誌優化** | **硬碟空間保護** | `sudo nano /etc/systemd/journald.conf`<br>`SystemMaxUse=500M` | |
| **IV. 清理 Host Key** | **防止 SSH 衝突** | `sudo rm -f /etc/ssh/ssh_host_*` | |
| **V. 清理記錄** | **網路/快取** | `sudo rm -f /etc/udev/rules.d/70-persistent-net.rules`<br>`sudo apt clean`<br>`history -c && rm -f ~/.bash_history` | |
| **VI. 製作範本** | **最後一步** | `sudo shutdown now` | |

---

## 💾 階段二：NFS 共享服務配置 (伺服器端: `192.168.8.40`)

| 階段 | 主題強調 | 設備 | 執行指令 / 內容 | 目的與說明 |
| :--- | :--- | :--- | :--- | :--- |
| **VII. 準備路徑** | **共享目錄** | 伺服器 | `sudo mkdir -p /home/ubn/Shared`<br>`sudo chown ubn:ubn /home/ubn/Shared` | |
| **VIII. 放置檔案** | **資料確認** | 伺服器 | `mv /home/ubn/run.sh /home/ubn/Shared/` | |
| **IX. 設定匯出** | **配置檔案位置** | 伺服器 | `sudo nano /etc/exports`<br>`/home/ubn/Shared 192.168.8.0/24(rw,sync,no_subtree_check)` | |
| **X. 啟用服務** | **立即生效** | 伺服器 | `sudo exportfs -ra`<br>`sudo systemctl restart nfs-server` | |

---

## 🔑 階段三：SSH 自動化與客戶端初始配置

| 階段 | 主題強調 | 設備 | 執行指令 / 內容 | 目的與說明 |
| :--- | :--- | :--- | :--- | :--- |
| **XI. 生成金鑰** | **管理機設置** | 管理機 | `ssh-keygen -t rsa -b 4096` | |
| **XII. 部署公鑰** | **無密碼前提** | 管理機 | `ssh-copy-id ubn@<目標VM的IP地址>` | |
| **XIII. 測試掛載** | **確認連線** | 客戶端 | `sudo mount 192.168.8.40:/home/ubn/Shared /mnt/getshare` | |
| **XIV. 設定 fstab** | **永久掛載** | 客戶端 | `sudo nano /etc/fstab` | |
| **XV. 新增配置** | **配置行內容** | 客戶端 | `192.168.8.40:/home/ubn/Shared /mnt/getshare nfs defaults,ro,hard,intr,noatime,x-systemd.automount 0 0` | |
| **XVI. 最終驗證** | **啟動檢查** | 客戶端 | `sudo mount -a`<br>`ls -l /mnt/getshare` | |
