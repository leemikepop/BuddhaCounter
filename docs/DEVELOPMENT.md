# 開發指南

給想參與開發、自行建置或維護「念佛計數器」的人。App 的介紹與使用方式見 [README](../README.md)。

改程式前請一定先讀 [AGENTS.md](../AGENTS.md)：裡面列了不能改的東西（套件 ID、儲存鍵、曲目編號）
與實際踩過的坑（iOS 音訊 session、原生循環播放器…）。

---

## 架構

```text
lib/
├── main.dart                 # 啟動：載入曲目 metadata、儲存、背景播放、通知，再交給 AppControllers
├── app/
│   ├── app_controllers.dart  # 組裝所有 controller (正式 App 與測試共用)
│   └── buddha_counter_app.dart  # MaterialApp、經典 / 現代切換、前景背景處理、跨午夜檢查
├── features/                 # 狀態與商業邏輯 (ChangeNotifier，不含畫面)
│   ├── settings/             # SettingsController、LocaleController、TapFeedback
│   ├── practice/             # PracticeController (今日計數、目標、月曆、提醒、小工具)、SessionStopwatch
│   ├── playback/             # PlaybackController (曲目、播放、進度、循環)
│   └── auto_count/           # AutoCountController、BeatTracker (純 Dart 節拍判斷)
├── core/
│   ├── constants/            # 31 首佛曲定義與時間標記 (chant_songs.dart)
│   ├── content/              # 曲目名稱、迴向文的各語言版本
│   ├── services/             # 儲存、音訊、背景播放 handler、通知、桌面小工具、功課紀錄
│   └── utils/                # 音檔 metadata 解析、時間格式
├── l10n/                     # ARB 翻譯檔與產生的 AppLocalizations
└── ui/
    ├── common/               # 兩種介面共用的元件 (Toast、跑馬燈、篩選列、AppBar 開關…)
    ├── legacy/               # 經典模式畫面與共用元件
    └── modern/               # 現代模式畫面、分頁、播放器面板、月曆、主題
```

### Controller 之間的關係

```text
SettingsController ──► TapFeedback ──► PracticeController ◄── AutoCountController
LocaleController (推送語言給曲目內容 / 通知 / 小工具 / 背景播放)         │
                                       PlaybackController ◄──────────────┘
                                         (delegate = AutoCountController)
```

- 每個畫面只 `watch` / `select` 自己需要的 controller，例如計時器每秒跳動只會重繪自動計數頁。
- **在自動計數畫面上，播放器的播放 / 暫停就是開始 / 暫停計數。** `AutoCountController` 實作
  `PlaybackDelegate` 並掛在 `PlaybackController.delegate`，播放器本身不需要知道計數規則。
- 自動計數的節拍判斷在 `BeatTracker`（純 Dart，有單元測試）：有時間標記的曲目跨過標記算一聲，
  沒有標記的曲目依平均節拍；切歌、循環回到開頭、拖曳進度條都有保護，不會多算。

### 播放引擎

| 平台 | 佛曲 | 點擊音效 |
|---|---|---|
| iOS | 原生 `ChantLoopPlayer`（`ios/Runner/ChantLoopPlayer.swift`，AVQueuePlayer + AVPlayerLooper，無縫循環） | audioplayers |
| Android | 原生 `ChantLoopPlayer`（`android/.../ChantLoopPlayer.kt`，兩個 MediaPlayer 以 setNextMediaPlayer 接力，無縫循環） | audioplayers（6 個播放器輪流） |
| Web | `WebAudioChantEngine`（`lib/core/services/web_chant_engine_web.dart`，Web Audio API 的 AudioBuffer 循環，無縫） | audioplayers |

兩個原生播放器用同一套通道，Dart 端都是 `NativeLoopChantEngine`；Web 用 `WebAudioChantEngine`。
三者都實作 `ChantMusicEngine` 介面，由 `ChantAudioHandler`（audio_service）統一對接系統媒體控制。

---

## 網頁版（GitHub Pages / PWA）

網址：<https://leemikepop.github.io/BuddhaCounter/>。主要給電腦瀏覽器使用；手機瀏覽器開啟時頂端會建議下載 App。

```bash
flutter run -d chrome                                   # 本機開發 (hot reload)
flutter build web --release --base-href /BuddhaCounter/  # 和 CI 部署相同的產物 (build/web)
```

- **部署**：`.github/workflows/deploy_web.yml`，推送 `v*` tag 或手動執行。第一次要在 Settings → Pages 把 Source 設成
  「GitHub Actions」；免費帳號的 Pages 只能用在公開 repo。
- **平台判斷一律用 `AppPlatform`**（`lib/core/platform/app_platform.dart`）。Web 上 `defaultTargetPlatform` 是瀏覽器所在的
  作業系統，iPhone 的 Safari 也會是 iOS；要判斷原生 App 用 `AppPlatform.isNativeIOS` / `isNativeAndroid`。
- **Web 上隱藏的功能**：每日提醒、桌面小工具、螢幕方向鎖定（`AppPlatform.supports*`）。對應的服務在 Web 上直接略過。
- **版面**：`lib/ui/web/web_frame.dart` 放在 `MaterialApp.builder`。視窗寬於 480 時，App 維持 480 寬置中，
  並把內部 `MediaQuery` 的寬度也改成 480；手機瀏覽器則在頂端顯示可關閉的「建議下載 App」。
- **音檔用到才下載**：Flutter Web 的資源檔是用到時才向伺服器抓。啟動時**不能**讀音檔：原生 App 會讀每個音檔的
  標籤取得演唱者，Web 改用 `lib/core/content/embedded_song_artists.dart`（換音檔後要更新，`test/embedded_song_artists_test.dart` 會檢查）。
- **PWA**：`web/manifest.json`、`web/index.html`（名稱、配色、載入畫面）。圖示由 `dart run flutter_launcher_icons` 一併產生到 `web/icons/`。
- 測試裡用 `AppPlatform.debugIsWebOverride = true` 模擬網頁版（見 `test/web_test.dart`）。

---

## 開發

需求：Flutter 3.47.x（stable）、Android Studio 或 VS Code。iOS 不需要 Mac 也能開發，建置交給 GitHub Actions（見下方）。

```bash
flutter pub get
flutter run                     # 在接上的裝置上執行
```

### 送出前的檢查

```bash
flutter analyze                 # 必須 No issues found
flutter test                    # 必須全部通過
bash tools/check_arb_parity.sh  # 三個語言的 key 與 placeholder 一致
bash tools/check_hardcoded_cjk.sh  # 程式碼裡沒有寫死的中文
dart format lib test            # 可選：統一格式
```

`analysis_options.yaml` 開了幾條可自動修正的規則，`dart fix --apply` 會處理。

### 多語言

- 模板是 **`lib/l10n/app_zh.arb`（繁中）**，另有 `app_zh_Hans.arb`、`app_en.arb`。
- 新增文字：三個 ARB 都加同一個 key（繁中檔要寫 `@key` 的 description），再執行 `flutter gen-l10n`。
  產生的 `lib/l10n/generated/` 要一起 commit。
- 曲目名稱與迴向文不在 ARB，而在 `lib/core/content/`。
- 用詞先查 [`lib/l10n/GLOSSARY.md`](../lib/l10n/GLOSSARY.md)。英文佛教用語已對照公開英譯修訂過一次，尚待熟悉佛教用語的人審閱。

### 測試

- `test/beat_tracker_test.dart`：節拍判斷（純邏輯）。
- `test/controllers_test.dart`：controller 行為與彼此的接線。
- `test/counter_test.dart`：計數、自動計數、月曆、各畫面的整合測試。
- `test/l10n_test.dart`：三種語言、語言切換、320dp 窄螢幕不溢位。
- `test/chant_music_engine_test.dart`、`test/audio_session_test.dart`：iOS / Android 播放引擎分流與音訊 session 設定。

共用工具在 `test/helpers/test_app.dart`（平台通道 mock、`AppControllers` 包裝、真實字型載入）。

### 商店截圖與宣傳圖

```bash
bash tool/screenshots/fetch_fonts.sh             # 第一次：下載 Noto Sans / Serif TC、SC（約 60 MB，不進 repo）
flutter test tool/screenshots                    # 約 1 分鐘，輸出到 build/screenshots/
bash tool/screenshots/export_store_assets.sh     # 把繁中宣傳圖複製到 assets/store_assets/（其他語言：zh_Hans / en）
```

不想在本機跑的話，到 GitHub → Actions → **Screenshots - Generate store images** → Run workflow
（或 `gh workflow run screenshots.yml --ref <branch>`），約 5 分鐘後在該次執行的頁面下載：

- `store-assets`：和 repo 裡相同的整理方式（繁中），解壓縮覆蓋 `assets/store_assets/` 後 commit。
- `screenshots-all-languages`：三種語言的原始截圖與宣傳圖（`build/screenshots/` 整個資料夾）。

artifact 保留 14 天；workflow 不會自己 commit 回 repo。

- 用真實的 `BuddhaCounterApp` 加上示範資料（今天 56 / 108 聲、自動 238 聲、約一個半月的功課紀錄）畫出來，
  不需要模擬器或 Mac。
- 原始截圖 `build/screenshots/<裝置>/<語言>/`：iPhone 6.9 吋（1320×2868）、iPad 13 吋（2064×2752）、
  Android 手機（1080×1920）× 繁中、簡中、英文；畫面清單在 `tool/screenshots/shots.dart` 的 `shots`。
- 宣傳圖 `build/screenshots/posters/`（`tool/screenshots/posters.dart`）：紙紋背景 + 明體標題 + 手機外框，
  外框裡是**真的在跑的 App**（有狀態列、動態島），不是貼上去的截圖。標題文字在 `_captions`。
  另外產生 README 首圖與 GitHub 社群預覽圖（只有繁中）。
- 文字一律用 Noto 排版，和 iPhone 實機的蘋方 / SF 略有不同。
- 截不到的：桌面小工具、通知、鎖定畫面播放控制（都是原生畫面），仍要手動截。
- 月初時功課月曆會自動切到上個月，避免大半個月是空的。
- 測試裡不能用 `Image.file`（讀檔卡在假時鐘裡會永遠等不到），一律先同步讀成 bytes 再用 `Image.memory`。

### 佛曲工作站（剪輯、轉檔、打時間標記）

雙擊 `tools/啟動佛曲工作站.bat`（需要 Node.js 與 ffmpeg），瀏覽器會打開 `tools/marker_recorder.html`：
可剪輯、轉成 `.ogg`、音量標準化、清理 metadata，並在聽的時候按鍵記錄每句佛號的時間標記，
產生的標記貼回 `lib/core/constants/chant_songs.dart`。

---

## 版本號

版本號只在 **`pubspec.yaml`** 管理（例如 `version: 1.54.5+161`），Gradle 與 Xcode 會自動帶入。

| 欄位 | 範例 | 意義 |
|---|---|---|
| `+` 前 | `1.54.5` | 使用者看到的版本（Android `versionName` / iOS `CFBundleShortVersionString`） |
| `+` 後 | `161` | 建置編號（Android `versionCode` / iOS `CFBundleVersion`） |

- **上傳 Google Play 或 TestFlight 前，建置編號一定要比上一次上傳的大**，否則商店會拒收。
- 只在自己手機測試、沒有上傳時，不需要改版本號。

---

## CI（GitHub Actions）

平常 `git push` **不會**自動建置（本機就能跑測試；repo 是私有的，macOS 機器的分鐘數是 Linux 的 10 倍）。

| Workflow | 觸發方式 | 做什麼 |
|---|---|---|
| `ci_android.yml` | 推送 `v*` tag、發布 Release、手動 | analyze、test、正式簽名 APK + AAB，並建立 GitHub Release |
| `deploy_ios_testflight.yml` | 推送 `v*` tag、發布 Release、手動 | 簽名 IPA 並上傳 TestFlight |
| `deploy_web.yml` | 推送 `v*` tag、手動 | analyze、test、建置網頁版並部署到 GitHub Pages |
| `ci_ios.yml` | 只能手動 | analyze、test、未簽名 IPA（給 Sideloadly 側載） |
| `screenshots.yml` | 只能手動 | 產生商店截圖與宣傳圖，打包成 artifact（見「商店截圖與宣傳圖」） |
| `codemagic.yaml` | 只能在 Codemagic 網頁手動開始 | 備用的 TestFlight 流程（目前沒在用） |

手動觸發：GitHub → Actions → 選 workflow → Run workflow，或
`gh workflow run ci_ios.yml --ref <branch>`。

### 發布新版本

```bash
# 1. 改 pubspec.yaml 的版本號 (建置編號 +1) 並 commit
# 2. 打 tag 推上去：Android Release 與 TestFlight 會同時開始建置
git tag v1.55.0
git push origin v1.55.0
```

### 需要的 Secrets

- Android（environment `Google Play Store`）：`KEYSTORE_BASE64`、`KEYSTORE_PASSWORD`、`KEY_ALIAS`、`KEY_PASSWORD`。
  沒設定時會退回 debug 簽名（產物不能上架）。
- iOS（environment `Apple Store Connect TestFlight`）：`BUILD_CERTIFICATE_BASE64`、`P12_PASSWORD`、
  `BUILD_PROVISION_PROFILE_BASE64`、`BUILD_WIDGET_PROVISION_PROFILE_BASE64`、`KEYCHAIN_PASSWORD`、
  `APP_STORE_CONNECT_ISSUER_ID`、`APP_STORE_CONNECT_KEY_ID`、`APP_STORE_CONNECT_PRIVATE_KEY`。

---

## Android 簽名與上架

- **Application ID 必須維持 `com.yichung.lee.count4`**，簽名金鑰是 `android/keystore/leeyc.jks`，
  這樣 Google Play 上的舊版使用者才能直接更新。
- 本機正式簽名：`cp android/key.properties.example android/key.properties`，填入密碼
  （此檔已被 `.gitignore` 排除）。沒有這個檔案時自動使用 debug 簽名。

```bash
flutter build apk --release        # 直接安裝用
flutter build appbundle --release  # 上傳 Google Play (build/app/outputs/bundle/release/app-release.aab)
```

---

## 在沒有 Mac 的情況下測試 iPhone

- **Sideloadly 側載**：手動執行 `ci_ios.yml`，下載 Artifacts 裡的 `.ipa`，用 [Sideloadly](https://sideloadly.io/)
  以個人 Apple ID 簽署安裝（免費帳號 7 天到期，重新安裝即可）。
  看 log：用 iMazing 的 Show Device Console 或 3uTools（愛思助手）的即時日誌，搜尋 `flutter:`
  （例如 `ChantLoopPlayer: loop mode: AVPlayerLooper (gapless)` 代表 iOS 正在使用無縫循環）。
- **TestFlight**：推送 `v*` tag 或手動執行 `deploy_ios_testflight.yml`。

> 側載會改寫 App Group，桌面小工具在側載版上可能讀不到資料（App 已嘗試多個可能的 group ID）。
> 小工具以 TestFlight / App Store 版為準。

---

## 已知限制

- iOS：來電等音訊中斷後，Dart 端不會收到「被中斷」的通知（播放鍵可能仍顯示播放中）。
- Android：通知頻道名稱在第一次建立後不會隨 App 語言切換而改名（Android 系統限制，重新安裝才會更新）。
- 英文佛教用語已對照公開英譯修訂過，但還沒經過熟悉佛教用語的人審閱（見 `lib/l10n/GLOSSARY.md`）。
- 網頁版：手機瀏覽器切到背景或鎖定螢幕時，瀏覽器可能暫停聲音；資料存在瀏覽器的 localStorage，清除網站資料就會消失。
- 320dp 窄螢幕測試需要 Flutter SDK 內附的 Roboto 字型；找不到時該測試會自動略過。

---

## 常用指令

```bash
flutter pub get                # 安裝套件
flutter devices                # 列出裝置
flutter run -d <DEVICE_ID>     # 指定裝置執行
flutter clean                  # 遇到奇怪的建置錯誤時清快取
flutter pub outdated           # 檢查套件新版本
dart run flutter_launcher_icons  # 依 pubspec.yaml 重新產生 App 圖示
flutter build ios --release --no-codesign  # 只在 macOS：未簽名 iOS 建置
```
