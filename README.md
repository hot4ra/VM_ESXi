# 🚀 Ubuntu VM 批量部署自動化指南 (NFS & SSH Key)

本專案提供了用於從零開始部署 Ubuntu VM 基礎設施的腳本和詳細配置流程，實現 NFS 共享和 SSH 無密碼登入。

---

## 📋 專案目標與特色

* **單一範本部署：** 透過一次性配置的範本 VM，快速複製出多台可用的客戶端 VM。
* **自動化配置：** 提供 Bash 腳本，自動完成 NFS 服務、SSH 金鑰部署和客戶端掛載配置。
* **無密碼管理：** 透過 SSH 金鑰，實現管理機對所有 VM 的無密碼連線管理。

---

## 🛠️ 前置要求 (Prerequisites)

1.  **虛擬化環境：** ESXi、VMware Workstation 或其他虛擬化平台。
2.  **VM 操作系統：** Ubuntu 20.04/22.04 LTS (或其他 Debian-based OS)。
3.  **網路規劃：** 確保所有 VM 位於同一個網段 (例如 `192.168.8.x`)。

---

## 📂 腳本目錄

所有腳本都位於 `scripts/` 資料夾內。

| 腳本名稱 | 執行位置 | 目的與功能 |
| :--- | :--- | :--- |
| `template_setup.sh` | **範本 VM** | 執行系統清理、安裝必要的服務，並移除 SSH Host Key。 |
| `nfs_server_setup.sh` | **伺服器 VM** | 創建 NFS 共享目錄，配置並啟用 NFS 匯出服務。 |
| `client_initial_config.sh` | **客戶端 VM** | 測試 NFS 連線，並永久寫入 `/etc/fstab` 配置，實現開機自動掛載。 |

---

## 💡 詳細部署流程

請嚴格按照以下步驟執行，以確保系統穩定性。

### 階段 1：建立基礎範本

1.  **將腳本上傳**到您準備用作範本的 VM (`ubn` 使用者的家目錄)。
2.  **執行腳本**並關機：

```bash
chmod +x template_setup.sh
./template_setup.sh
sudo shutdown now
