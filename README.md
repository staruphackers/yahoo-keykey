# Yahoo KeyKey 現代化安裝器

這個專案用來重新封裝 Yahoo! KeyKey 輸入法，讓舊版輸入法可以用較新的 macOS installer 流程安裝到現代 Mac。

Yahoo! KeyKey 已停止維護多年，原始安裝器使用 Apple 已棄用的 PackageMaker，無法符合現代 macOS 的簽章、Gatekeeper 與安裝流程需求。本專案不是 Yahoo 官方版本，也不是完整重寫輸入法核心；目前重點是把既有可執行檔整理成較穩定、可重建、可簽章的安裝包。

## 目前狀態

目前版本提供 Apple Silicon / M 系列 Mac 的 Rosetta 相容安裝包。

既有 Yahoo! KeyKey app 內含 `x86_64` binary，但沒有 `arm64` binary。因此在 M1、M2、M3、M4、M5 等 Apple Silicon Mac 上，這個版本會透過 Rosetta 執行，而不是原生 arm64 執行。

這版已針對現代 macOS 做以下整理：

- 移除無法在現代 macOS 執行的 32-bit-only helper apps
- 將主要輸入法與 bundled frameworks 精簡為 `x86_64`
- 更新 bundle metadata，避免舊版架構資訊干擾安裝
- 建立 staging 流程，封裝前先整理 app bundle
- 預設對 staged app 做 ad-hoc codesign
- 在 Apple Silicon 安裝前檢查 Rosetta，必要時自動安裝
- 安裝後重新註冊輸入法，並刷新相關 macOS 快取

## 產生安裝包

需求：

- macOS
- Xcode command line tools
- 可選：Developer ID Application 憑證
- 可選：Developer ID Installer 憑證

建立本機未簽章 installer：

```sh
./build.sh
```

產物會輸出到：

```text
build/YahooKeyKey-modern.pkg
```

也可以執行驗證流程：

```sh
./script/build_and_run.sh --verify
```

驗證流程會檢查 staged app 的 binary 架構、codesign、installer XML 與 plist 格式。

## 安裝方式

本機測試可使用：

```sh
sudo installer -pkg build/YahooKeyKey-modern.pkg -target /
```

安裝完成後，建議登出再登入，或重新啟動 macOS，讓輸入法清單重新載入。

## 簽章發佈

預設 build 會對 app bundle 做 ad-hoc codesign，適合本機測試與開發。

若要讓 pkg 更容易通過 Gatekeeper 並適合對外發佈，請提供 Developer ID Application 與 Developer ID Installer 憑證：

```sh
APP_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
INSTALLER_SIGN_IDENTITY="Developer ID Installer: Your Name (TEAMID)" \
./build.sh
```

沒有 `INSTALLER_SIGN_IDENTITY` 時，外層 pkg 不會有 Developer ID Installer 簽章；這種 pkg 可能無法直接用 Finder 雙擊安裝，但仍可用 `sudo installer` 做本機測試。

## 原生 arm64 路線

真正的 Apple Silicon 原生版本需要重新編譯輸入法核心與相關 framework。公開可取得的舊版 source 目前有幾個關鍵阻礙：

- 專案格式與 Xcode 設定非常老，需要大量升級
- 舊版 Interface Builder 檔案目標過低，需要轉換
- 詞庫使用的 SQLite CEROD / SEE 元件不是公開 source 的完整內容
- 現有 `KeyKey.db` 不是一般 sqlite database，不能直接用系統 sqlite3 讀取

因此，短期可行方案是維護 Rosetta 相容安裝包；中長期若要原生 arm64，需要處理詞庫格式、輸入法核心移植，或改以現代 OpenVanilla / McBopomofo 等維護中的基礎重新整合。

更多細節請見：

```text
docs/modernization-roadmap.md
```

## 專案結構

```text
root/                         既有 Yahoo! KeyKey app 與安裝內容
Scripts/preinstall            安裝前檢查與 Rosetta 準備
Scripts/postinstall           安裝後輸入法註冊與快取刷新
script/prepare_modern_stage.sh 封裝前整理 staging bundle
script/build_and_run.sh        建立與驗證 installer
script/audit_bundle.sh         檢查 staged app binary 與 codesign
docs/                          現代化與原生化路線文件
```

## 免責說明

Yahoo! KeyKey 是已停止維護的舊輸入法。本專案僅針對既有安裝包做現代化封裝與相容性改善，未宣稱與 Yahoo 官方有任何關係。
