# 🚀 從零開始：VM 基礎設施部署與管理指南 (NFS + SSH 自動化)

本指南包含 VM 範本 (Template) 的最佳化準備、NFS 共享服務的配置，以及所有客戶端 VM 的 SSH 無密碼設定與正確初始掛載流程。

---

## 🎯 階段一：基礎 VM 範本準備與通用化 (Template Generalization)

在製作 VM 範本前，移除 VM 獨特的識別符是防止網路和 SSH 衝突的關鍵步驟。

| 階段 | 主題強調 | 執行指令 | 目的與說明 |
| :--- | :--- | :--- | :--- |
| **I. 預裝服務** | **所有 VM 必備** | `sudo apt update`<br>`sudo apt install -y openssh-server nfs-common nfs-kernel-server` | 安裝 SSH 伺服器和 NFS 共享所需的所有工具。 |
| **II. 創建掛載點** | **客戶端準備** | `sudo mkdir -p /mnt/getshare` | 預先創建 NFS 掛載點，方便後續配置。 |
| **III. 日誌優化** | **硬碟空間保護** | **編輯:** `sudo nano /etc/systemd/journald.conf` <br>**設定:** `SystemMaxUse=500M` | 限制系統日誌大小，防止根目錄 `/` 被佔滿。 |
| **IV. 清理 Host Key** | **防止 SSH 衝突** | `sudo rm -f /etc/ssh/ssh_host_*` | **最關鍵！** 移除主機唯一識別符，確保複製出的 VM 啟動時自動生成新 Key。 |
| **V. 清理記錄** | **網路/快取** | `sudo rm -f /etc/udev/rules.d/70-persistent-net.rules`<br>`sudo apt clean`<br>`history -c && rm -f ~/.bash_history` | 清理舊的 MAC 地址綁定記錄、系統快取和 Bash 歷史記錄。 |
| **VI. 製作範本** | **最後一步** | `sudo shutdown now` | 正常關機，然後在 ESXi 中將此 VM 轉換為範本。 |

---

## 💾 階段二：NFS 共享服務配置 (伺服器端: `192.168.8.40`)

將其中一台 VM 配置為 NFS 伺服器，並設定共享路徑為 `/home/ubn/Shared`。

| 階段 | 主題強調 | 設備 | 執行指令 / 內容 | 目的與說明 |
| :--- | :--- | :--- | :--- | :--- |
| **VII. 準備路徑** | **共享目錄** | 伺服器 | `sudo mkdir -p /home/ubn/Shared`<br>`sudo chown ubn:ubn /home/ubn/Shared` | 創建共享目錄並確保 `ubn` 擁有者權限。 |
| **VIII. 放置檔案** | **資料確認** | 伺服器 | `mv /home/ubn/run.sh /home/ubn/Shared/` | 將要共享的檔案放入正確路徑。 |
| **IX. 設定匯出** | **配置檔案位置** | 伺服器 | **編輯：** `sudo nano /etc/exports` | 以 root 權限編輯 NFS 匯出配置。 |
| **X. 匯出路徑** | **IP 與路徑** | 伺服器 | **新增：** `/home/ubn/Shared 192.168.8.0/24(rw,sync,no_subtree_check)` | 允許 $192.168.8.x$ 網段存取正確的路徑。 |
| **XI. 啟用服務** | **立即生效** | 伺服器 | `sudo exportfs -ra`<br>`sudo systemctl restart nfs-server` | 重新載入配置並重啟 NFS 服務。 |

---

## 🔑 階段三：SSH 自動化與客戶端初始配置

這是配置管理機和所有客戶端 VM 的關鍵步驟，實現無密碼登入並設定正確的 `fstab`。

### 1. SSH 金鑰設置 (實現無密碼連線)

| 階段 | 主題強調 | 執行指令 | 目的與說明 |
| :--- | :--- | :--- | :--- |
| **XII. 生成金鑰** | **管理機設置** | `ssh-keygen -t rsa -b 4096` | 在 MobaXterm Local Terminal 或 管理機上執行，生成公鑰 (`~/.ssh/id_rsa.pub`)。 |
| **XIII. 部署公鑰** | **自動化前提** | `ssh-copy-id ubn@<目標VM的IP地址>` | **必須** 將公鑰部署到所有客戶端和伺服器 VM。實現無密碼登入。 |

### 2. 客戶端 VM 初始掛載配置

在所有客戶端 VM 首次啟動，並部署完 SSH 金鑰後，執行此步驟。

| 階段 | 主題強調 | 設備 | 執行指令 / 內容 | 目的與說明 |
| :--- | :--- | :--- | :--- | :--- |
| **XIV. 測試掛載** | **確認連線** | 客戶端 | `sudo mount 192.168.8.40:/home/ubn/Shared /mnt/getshare` | 確保網路和 NFS 服務正常。 |
| **XV. 設定 fstab** | **永久掛載** | 客戶端 | **編輯：** `sudo nano /etc/fstab` | **必須** 以 root 權限編輯。 |
| **XVI. 新增配置** | **正確配置行** | 客戶端 | **新增以下行:** | 寫入正確的伺服器 IP 和路徑，確保開機自動掛載。 |

```ini
# NFS 共享配置 (伺服器 IP: 192.168.8.40 / 共享路徑: /home/ubn/Shared)
192.168.8.40:/home/ubn/Shared /mnt/getshare nfs defaults,ro,hard,intr,noatime,x-systemd.automount 0 0
