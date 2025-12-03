# 🚀 虛擬機基礎設施部署與管理指南 (NFS + SSH 自動化)

本文件整理了從 VM 範本 (Template) 準備到 NFS 共享配置，以及使用 SSH 金鑰實現批量自動化管理的完整流程。

---

## 🎯 階段一：VM 範本準備與通用化 (Template Generalization)

在製作 VM 範本前，移除 VM 獨特的識別符是防止網路和 SSH 衝突的關鍵。

| 階段 | 主題強調 | 執行指令 | 目的與說明 |
| :--- | :--- | :--- | :--- |
| **I. 預裝服務** | **所有 VM 必備** | `sudo apt update`<br>`sudo apt install -y openssh-server nfs-common nfs-kernel-server` | 安裝 SSH 伺服器和 NFS 共享所需的所有工具。 |
| **II. 日誌優化** | **硬碟空間保護** | **編輯:** `sudo nano /etc/systemd/journald.conf` <br>**設定:** `SystemMaxUse=500M` | 限制系統日誌大小，防止根目錄 `/` 被佔滿。 |
| **III. 清理 Host Key** | **防止 SSH 衝突** | `sudo rm -f /etc/ssh/ssh_host_*` | **最關鍵！** 移除主機唯一識別符，確保複製出的 VM 啟動時自動生成新 Key。 |
| **IV. 清理記錄** | **網路/快取** | `sudo rm -f /etc/udev/rules.d/70-persistent-net.rules`<br>`sudo apt clean`<br>`history -c && rm -f ~/.bash_history` | 清理舊的 MAC 地址綁定記錄、系統快取和 Bash 歷史記錄。 |
| **V. 製作範本** | **最後一步** | `sudo shutdown now` | 正常關機，然後在 ESXi 中將此 VM 轉換為範本。 |

---

## 💾 階段二：NFS 共享服務配置 (伺服器端: `192.168.8.40`)

將其中一台 VM 配置為 NFS 伺服器，並設定共享路徑為 `/home/ubn/Shared`。

| 階段 | 主題強調 | 設備 | 執行指令 / 內容 | 目的與說明 |
| :--- | :--- | :--- | :--- | :--- |
| **VI. 準備路徑** | **共享目錄** | 伺服器 | `sudo mkdir -p /home/ubn/Shared`<br>`sudo chown ubn:ubn /home/ubn/Shared` | 創建共享目錄並確保 `ubn` 擁有者權限 (解決 `Permission denied`)。 |
| **VII. 放置檔案** | **資料確認** | 伺服器 | `mv /home/ubn/run.sh /home/ubn/Shared/` | 將要共享的檔案放入正確路徑。 |
| **VIII. 設定匯出** | **配置檔案位置** | 伺服器 | **編輯：** `sudo nano /etc/exports` | 以 root 權限編輯 NFS 匯出配置。 |
| **IX. 匯出路徑** | **IP 與路徑** | 伺服器 | **新增：** `/home/ubn/Shared 192.168.8.0/24(rw,sync,no_subtree_check)` | 允許 $192.168.8.x$ 網段存取正確的路徑。 |
| **X. 啟用服務** | **立即生效** | 伺服器 | `sudo exportfs -ra`<br>`sudo systemctl restart nfs-server` | 重新載入配置並重啟 NFS 服務。 |

---

## 🔑 階段三：SSH 自動化與客戶端批量管理

這是實現無密碼管理和自動化配置的流程。

### 1. SSH 金鑰設置 (實現無密碼連線)

| 階段 | 主題強調 | 執行指令 | 目的與說明 |
| :--- | :--- | :--- | :--- |
| **XI. 生成金鑰** | **管理機設置** | `ssh-keygen -t rsa -b 4096` | 在 MobaXterm Local Terminal 或 管理機上執行，生成公鑰 (`~/.ssh/id_rsa.pub`)。 |
| **XII. 部署公鑰** | **自動化前提** | `ssh-copy-id ubn@<目標VM的IP地址>` | **必須** 將公鑰部署到所有客戶端和伺服器 VM。此為最後一次需要輸入密碼。 |

### 2. 客戶端配置批量更新腳本

使用此腳本可一鍵修正客戶端 VM `/etc/fstab` 中的舊 IP 地址和路徑。

> 💡 **使用方法:** 將以下內容儲存為 `update_fstab.sh`，賦予執行權限 (`chmod +x update_fstab.sh`)，然後執行 `./update_fstab.sh`。

```bash
#!/bin/bash

# --- 固定配置變數 ---
USER="ubn"
OLD_PATH="/home/ubn/share"   # 客戶端 fstab 中現有的舊路徑部分
NEW_PATH="/home/ubn/Shared"  # 共享伺服器上正確的新路徑部分
MOUNT_POINT="/mnt/getshare"
SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# --- 互動輸入 ---
echo "================================================"
echo "  客戶端 NFS 配置自動更新工具"
echo "================================================"
read -p "1. 請輸入要修改的客戶端 VM IP: " CLIENT_IP
read -p "2. 請輸入客戶端 fstab 中現有的【舊共享 IP】: " OLD_SHARE_IP
read -p "3. 請輸入新的共享 VM IP: " NEW_SHARE_IP

# 構建替換字串
OLD_CONFIG="${OLD_SHARE_IP}:${OLD_PATH}"
NEW_CONFIG="${NEW_SHARE_IP}:${NEW_PATH}"

echo "--- 正在連線並自動更新 ${CLIENT_IP} ---"

# --- 遠端 SSH 命令執行 (利用金鑰實現無密碼操作) ---
ssh ${USER}@${CLIENT_IP} ${SSH_OPTIONS} "
  echo '1. 正在替換 fstab 中的 NFS 共享配置...'
  sudo sed -i 's|${OLD_CONFIG}|${NEW_CONFIG}|g' /etc/fstab;

  echo '2. 正在嘗試卸載舊的掛載點 ${MOUNT_POINT}...'
  sudo umount -l ${MOUNT_POINT};

  echo '3. 正在應用新的 fstab 配置並重新掛載...'
  sudo mount -a;
  
  echo '4. 驗證新的掛載狀態...'
  mount | grep getshare;
"

echo "--- 客戶端 ${CLIENT_IP} 配置更新完成 ---"
