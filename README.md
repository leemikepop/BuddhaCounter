# 念佛計數器 (BuddhaCounter) - Flutter 跨平台移植版

> **傳承與初心**：本專案由 李一中（阿忠）居士創立開發，原為 Android 原生應用程式（`Count3` / `com.yichung.lee.count4`）。  
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
│   ├── app/build.gradle           # applicationId: com.yichung.lee.count4
│   └── keystore/                  # 原版 leeyc.jks 簽名金鑰庫
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

### 方案 B：App Store Connect + TestFlight 雲端測試（適合正式發布前）
- 若您擁有 Apple Developer 開發者帳號（$99/年）：
- 可在 GitHub Actions 中配置 Fastlane 或 App Store Connect API Key，CI 完成後直接自動上傳至 **TestFlight**。
- 您（與其他測試同修）只需在 iPhone 12 Pro 安裝 TestFlight App，隨時接收推播更新並一鍵點擊安裝，免接電腦且效期長達 90 天。

---

## 🛠 本地開發啟動命令 (若已安裝 Flutter)

```bash
# 1. 取得套件依賴
flutter pub get

# 2. 連接 Android 裝置或模擬器運行
flutter run
```
