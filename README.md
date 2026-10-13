# 念佛計數器 (BuddhaCounter) - Flutter 跨平台移植版

> **傳承與初心**：本專案由 李義忠（阿忠）居士創立開發，原為 Android 原生應用程式（`Count3` / `com.yichung.lee.count4`）。  
> 現由新世代接棒現代化維護，完整重構移植為 **Flutter** 跨平台專案，支援 Android 與 iOS 雙平台。

---

## 🌟 核心特色與架構

1. **原汁原味經典復古模式 (Legacy UI)**：
   - 忠實復刻父親原創版面（頂部藍底白字聖號、淡黃控制列、超大「按我」主按鈕、淡綠計時區）。
   - 保留長輩與老同修最熟悉的視覺與操作習慣。
   - 支援經典「念佛頁面（大回向西方文與阿彌陀佛聖像）」、「念佛自動計數（Main6Activity）」、「31 首經典佛號曲目清單」與「阿忠小站（緣起傳承）」。

2. **預留現代禪意模式 (Modern UI)**：
   - 全新極簡現代禪意設計，結合圓環計數、微動效反饋與沉浸體驗。
   - 可在設定中一鍵於「經典模式」與「現代模式」之間自由切換，共用底層同一個計數與音訊狀態模型。

3. **完整信仰音訊資產遷移**：
   - 木魚敲擊音效（`mus.mp3`）、引磬悠揚音效（`ens.mp3`）。
   - 31 首經典佛號唱誦錄音（淨空老法師、靈巖山寺、印光大師、朝山、地鐘念佛、六字大明咒等）。

4. **上架相容性保證**：
   - Android Application ID：嚴格保持 `com.yichung.lee.count4`，確保 Google Play 現有版本可直接發布更新。
   - 保留原簽名金鑰庫 `android/keystore/leeyc.jks` 與 `private_key.pepk`。

---

## 📁 專案目錄結構

```text
BuddhaCounter/
├── .github/
│   └── workflows/
│       ├── build_ios.yml          # GitHub Actions 免 Mac 自動編譯 iOS IPA
│       └── build_android.yml      # GitHub Actions 自動編譯 Release APK / AAB
├── android/
│   ├── app/build.gradle.kts       # applicationId: com.yichung.lee.count4, compileSdk 37
│   ├── keystore/                  # 原版 leeyc.jks 簽名金鑰庫與 private_key.pepk
│   └── key.properties.example     # 本地簽名設定範本 (密碼不入 Git)
├── assets/
│   ├── audio/                     # 33 個完整音訊檔 (bb1~bb31, mus, ens)
│   └── images/                    # 阿彌陀佛聖像與 App 圖示
├── ios/
│   └── Runner/Info.plist          # iOS 顯示名稱與背景音訊播放設定
├── lib/
│   ├── core/                      # 常數、音訊播放服務、本地持久化儲存
│   ├── features/counter/          # 計數器與計時器狀態管理 (ViewModel)
│   ├── ui/
│   │   ├── legacy/screens/        # 經典復古版 6 大畫面 (MainActivity 復刻)
│   │   └── modern/screens/        # 現代禪意版畫面
│   └── main.dart                  # 應用程式進入點與模式切換控制器
└── pubspec.yaml
```

---

## 📱 無 macOS 環境下測試 iPhone 12 Pro 的最佳指南

由於您目前在 Windows 環境、手邊無實體 Mac 電腦，針對 **iPhone 12 Pro** 測試的完整解決方案如下：

### 方案 A：GitHub Actions + Sideloadly / AltStore 側載（最推薦快速自測）
1. 將專案推送到 GitHub Repository。
2. 在 GitHub 的 **Actions** 頁籤觸發 `Build iOS IPA` 工作流。
3. 工作流會在 GitHub 官方提供的 macOS 虛擬機中完成編譯，並在 Actions 摘要頁產出 `BuddhaCounter-iOS-unsigned-ipa` 檔案。
4. 下載 `.ipa` 到 Windows 電腦。
5. 使用 Windows 免費開源工具 **[Sideloadly](https://sideloadly.io/)** 或 **AltStore**：
   - 將 iPhone 12 Pro 接上傳輸線連接電腦。
   - 在 Sideloadly 中拖入該 `.ipa`，輸入您的個人免費 Apple ID 帳號進行簽署。
   - 點擊「Start」，App 就會直接安裝到您的 iPhone 12 Pro 手機桌面！
   *(附註：個人免費 Apple ID 簽名效期為 7 天，到期若要繼續測試只要重新點一次安裝即可)*

### 方案 B：GitHub Actions 自動簽名並直推 TestFlight（雲端自動化）
專案已配置完整的 TestFlight CI 流水線（支援 `apple-actions/upload-testflight-build@v5`）。只要在 GitHub Repository Secrets 配置 Apple 憑證與 App Store Connect API Key：
- 每次 `git push` 即會自動在 macOS Runner 匯入證書並編譯為 App Store 正式版 IPA，且**自動直接上傳至 TestFlight**。
- 您（與其他測試同修）只需在 iPhone 安裝 TestFlight App，隨時接收推播更新並一鍵點擊安裝，免接電腦且效期長達 90 天。

---

## 📦 版本號管理與規範 (Version Code / Version Name)

本專案為 Flutter 跨平台專案，版本號由 **[`pubspec.yaml`](pubspec.yaml)** 單一來源管理，**請勿直接在 Gradle 或 Xcode 設定檔中寫死版本號**。

在 `pubspec.yaml` 中：
```yaml
version: 1.48.0+148
```

| 欄位 | 範例 | 說明 |
| :--- | :--- | :--- |
| **`+` 前方 (Version Name)** | `1.48.0` | **使用者視覺版本號**。對應 Android 的 `versionName` 與 iOS 的 `CFBundleShortVersionString`。遵循語義化版本規範（主版本.次版本.修訂號）。 |
| **`+` 後方 (Version Code)** | `148` | **系統與商店識別編號**。對應 Android 的 `versionCode` 與 iOS 的 `CFBundleVersion`。必須為整數，**每次發布 Google Play 更新時必須嚴格累加（+1）**，否則商店會拒絕上架。 |

> 📌 **自動同步機制**：`android/app/build.gradle.kts` 已配置 `versionCode = flutter.versionCode` 與 `versionName = flutter.versionName`，每次編譯時 Flutter 會自動將版本號注入雙平台。

---

## 🔏 Android 正式簽章部署與 Fallback 機制

本專案保留了原版原生應用的發布簽名金鑰庫（位於 `android/keystore/leeyc.jks`）。為兼顧安全性與開發便利性，Gradle 建置系統採用了**三層智慧簽署與安全回退（Fallback）機制**：

### 1. 簽署載入優先順序
1. **本機正式簽章**：若存在 `android/key.properties` 且包含有效密碼，使用 `leeyc.jks` 正式簽名。
2. **CI 自動簽章**：若在 GitHub Actions 且已配置 Repository Secrets，從環境變數讀取並進行正式簽名。
3. **安全回退 (Fallback)**：若以上皆無配置，自動回退為 **`debug` 簽名**，確保任何人 clone 專案後皆能直接順利編譯測試，絕不報錯中斷。

### 2. 本機設定步驟（建立正式簽名包）
1. 複製範本檔建立本地密碼檔（此檔案已被 `.gitignore` 排除，絕不會外洩到 Git）：
   ```bash
   cp android/key.properties.example android/key.properties
   ```
2. 編輯 `android/key.properties` 填入實際金鑰密碼：
   ```properties
   storeFile=../keystore/leeyc.jks
   storePassword=<金鑰庫密碼>
   keyAlias=leeyc
   keyPassword=<金鑰別名密碼>
   ```
3. 執行正式打包：
   ```bash
   # 產出正式簽名 APK (手動安裝)
   flutter build apk --release

   # 產出正式簽名 AAB (Google Play 上架)
   flutter build appbundle --release
   ```

---

## 🚀 CI/CD 與特定版本發布流程 (GitHub Actions)

專案已內建完整的自動化 CI/CD 流水線，並**嚴格區分日常開發與正式發布**，避免每次 commit 都產生多餘版本：

### 情況 A：日常程式碼提交 (`git push` 到 `main` / PR)
* **僅自動觸發 iOS 建置驗證**（Android 已設定為本地 Windows 編譯或正式 Release 時才觸發，以節省 Actions 運算配額）。
* iOS 編譯產物以 **Artifacts** 形式暫存於 GitHub Actions 執行紀錄中（供側載除錯驗證），**不會建立任何 GitHub Release**。

### 情況 B：發布特定版本（推薦：使用 Git Tag）
當您完成某個功能階段、並已在 `pubspec.yaml` 遞增好版本號後，只需對該 commit 建立版本標籤並推送：

```bash
# 1. 確保已 commit 最新程式碼 (包含 pubspec.yaml 版本號更新)
git add .
git commit -m "chore: release v1.48.0"

# 2. 建立 tag 並推送到遠端
git tag v1.48.0
git push origin v1.48.0
```

**GitHub Actions 偵測到 `v*` 標籤後會自動執行：**
1. 啟動 Android 與 iOS 雙平台編譯。
2. 自動在 GitHub 倉庫的 **Releases** 頁面建立 `v1.48.0` 正式發布版本。
3. 自動生成變更紀錄（Release Notes），並自動將產物掛載至該 Release 供同修下載：
   - 📱 `app-release.apk`（Android 正式安裝包）
   - 📦 `app-release.aab`（Google Play 上架套件）
   - 🍏 `BuddhaCounter.ipa`（iOS 正式簽名安裝包 / TestFlight 版本）

### 情況 C：在 GitHub 網頁上手動一鍵發布 (Workflow Dispatch)
若不想使用命令列打 tag，也可隨時在網頁上手動觸發：
1. 瀏覽 GitHub 倉庫 ➡️ 點選 **Actions** 頁籤。
2. 左側點擊 **Build Android Release**。
3. 點選右側 **Run workflow** 下拉選單。
4. 勾選 **`是否直接建立 GitHub Release (附帶 APK / AAB 檔案)`**。
5. 點擊綠色 **Run workflow** 按鈕即可指定發布。

### 情況 D：在 GitHub Actions 啟用正式簽名（選用）
若希望 GitHub Actions 自動產出的檔案也具備原作者正式簽名：
1. 進入 GitHub 倉庫 ➡️ **Settings** ➡️ **Secrets and variables** ➡️ **Actions**。
2. 點擊 **New repository secret**，新增以下 3 個變數：
   - `KEYSTORE_PASSWORD`：金鑰庫密碼
   - `KEY_ALIAS`：金鑰別名（例如 `leeyc`）
   - `KEY_PASSWORD`：別名密碼
*(若未設定，CI 會自動安全 fallback 至 debug 簽名)*

---

## 🏪 Google Play 無縫更新指南

本專案已嚴格保留原原生 Android App 的識別參數：
* **Application ID**：`com.yichung.lee.count4`
* **Sign Key**：`android/keystore/leeyc.jks`

**更新上架步驟：**
1. 更新 `pubspec.yaml` 的版本號（確保 `versionCode` 大於上一版）。
2. 使用正式金鑰打包 AAB：
   ```bash
   flutter build appbundle --release
   ```
3. 登入 [Google Play Console](https://play.google.com/console/)。
4. 進入既有的「念佛計數器」應用 ➡️ **正式版本 (Production)** ➡️ **建立新發布版本**。
5. 上傳 `build/app/outputs/bundle/release/app-release.aab`。
6. 填寫版本說明並提交審查，即可無縫覆蓋更新老使用者的應用程式！

---

---

## 🛠 常用 Flutter 指令速查表 (Cheat Sheet)

### 🎨 1. 更新應用程式圖示 (App Icon)
當替換新圖示或修改圖示設定時使用：
```bash
# 根據 pubspec.yaml 中的 flutter_launcher_icons 設定一鍵生成雙平台圖示
dart run flutter_launcher_icons
```
> **圖示更新流程提醒：**
> 1. 將 1024×1024 無透明背景的高解析度 PNG 圖檔放入 `assets/images/`（例如 `assets/images/app_icon_new.png`）。
> 2. 確認 `pubspec.yaml` 中的 `image_path` 指向該圖檔。
> 3. 執行 `dart run flutter_launcher_icons` 即可自動覆蓋 Android (`mipmap-*`) 與 iOS (`AppIcon.appiconset`)。
> 4. 若 Android 編譯提示資源衝突，可執行 `flutter clean` 後再重新編譯。

---

### 💻 2. 日常開發與偵錯
```bash
# 取得並同步套件依賴
flutter pub get

# 檢查本機開發環境與工具鏈狀態
flutter doctor -v

# 列出當前連接的實體裝置與模擬器
flutter devices

# 啟動應用並進行即時除錯 (Debug Mode)
flutter run

# 指定特定裝置啟動 (例如 Chrome 或特定手機)
flutter run -d chrome
flutter run -d <DEVICE_ID>
```

---

### 🧹 3. 程式碼檢查與清理
```bash
# 執行靜態程式碼分析 (找出語法錯誤與警告)
flutter analyze

# 自動格式化整個專案的 Dart 程式碼
dart format .

# 執行單元測試
flutter test

# 清理編譯快取 (遇到詭異建置錯誤或資源衝突時首選)
flutter clean
```

---

### 📦 4. 依賴套件管理
```bash
# 檢查哪些依賴套件有新版本可升級
flutter pub outdated

# 在相容的版本限制內升級套件
flutter pub upgrade
```

---

### 🚀 5. 編譯與打包發布
```bash
# 【Android】編譯正式版 APK (可直接安裝於手機測試)
flutter build apk --release

# 【Android】編譯正式版 AAB (Google Play 上架專用)
flutter build appbundle --release

# 【iOS】編譯免簽名版本 (供 AltStore / Sideloadly 側載使用)
flutter build ios --release --no-codesign

# 【iOS】編譯正式發布歸檔 (TestFlight / App Store 上架使用)
flutter build ipa --release
```


