# AGENTS.md

給在這個 repo 工作的開發者與 AI 助理。功能與一般說明見 [README.md](README.md)；
這裡只寫**改程式前一定要知道的規則**，大多是實際踩過的坑。

## 工作方式

- 先在分支上改，**commit 在本機**；要 push、開 PR、觸發 CI 前先問 repo 主人。
- **不要自己把 App 安裝到主人的手機上**，要裝之前先問。
- 每次送出前：`flutter analyze`（零問題）、`flutter test`（全過）、`bash tools/check_arb_parity.sh`、
  `bash tools/check_hardcoded_cjk.sh`。可自動修的 lint 用 `dart fix --apply`。
- 只改到 Android 時，本機 `flutter build apk --debug` 就能驗證；iOS 只能靠 GitHub Actions（見「CI」）。
- 不要動版本號，除非主人要上傳 TestFlight / Google Play（見「版本號」）。

## 架構規則

- 狀態都在 `lib/features/**` 的 `ChangeNotifier` controller，畫面只負責顯示。
  所有 controller 在 `lib/app/app_controllers.dart` 組裝；**新增 controller 也加在這裡**，
  測試用 `AppControllers.create(storage: ..., audio: ...)` 拿到同一套接線，用 `app.provide(child: ...)` 包畫面。
- 畫面用 `context.select` / `context.watch` 只監聽需要的那一個 controller；動作用 `context.read`。
  播放進度走 `PlaybackController.positionListenable` / `durationListenable`（ValueNotifier），
  **不要讓進度變化觸發 `notifyListeners()`**，否則播放中整頁每秒重繪好幾次。
- 自動計數與播放器的關係：`AutoCountController` 實作 `PlaybackDelegate` 並掛到
  `PlaybackController.delegate`。在自動計數畫面（`setScreenVisible(true)`）或計數中，播放器的
  播放 / 暫停 / 換曲會交給自動計數處理。進出自動計數畫面一定要呼叫 `setScreenVisible`。
- 節拍判斷邏輯只放在 `lib/features/auto_count/beat_tracker.dart`（純 Dart），改了要跑
  `test/beat_tracker_test.dart`。
- 「今天的計數」(`PracticeController.count` / `autoCount`) 跨午夜會由 `checkDateRollover()` 歸零；
  修改任何一天的紀錄要走 `PracticeController`（不要直接改 `PracticeRecordService`），今天的數字才會同步。
- 經典模式（`lib/ui/legacy/`）要保留，版面沿用最早的 Android 版，不要改成現代風格。
  共用按鈕 / 橫幅 / 顏色在 `lib/ui/legacy/widgets/legacy_widgets.dart`。
- 現代模式的淺 / 深色配色集中在 `lib/ui/modern/theme/modern_palette.dart`，新元件請用它，
  不要再寫 `isDark ? Color(..) : Color(..)`。

## 相容性：不能改的東西

- Android `applicationId` = `com.yichung.lee.count4`、簽名金鑰 `android/keystore/leeyc.jks`
  （Google Play 舊版使用者靠這兩個才能直接更新）。
- `StorageService` 裡的偏好鍵名稱（例如 `DormancyCB1`、`autoCounter`、`autoTsec`、`stopTime`）是舊版沿用下來的，
  **改名會讓使用者的資料消失**。要換格式就寫遷移。
- `ChantSong.id` 與 `assets/audio/` 的順序對應使用者存下的「上次播放曲目」與自動計數標記，不要重新編號。

## iOS 音訊（最容易出錯）

- 整個 App 只有**一份** `AVAudioSession`。只在 `ChantAudioHandler.configureIosAudioSession()` 用
  `AudioPlayer.global.setAudioContext` 設定一次：`playback`、**不加任何 option**。
  - 加 `mixWithOthers`：iOS 不把 App 當成 Now Playing，控制中心 / 鎖定畫面的播放控制會消失。
  - 加 `defaultToSpeaker`：只能配 `playAndRecord`，配 `playback` 會讓整組設定失敗。
  - **iOS 上不要對任何單一 `AudioPlayer` 呼叫 `setAudioContext`**（會覆蓋全域 session）。點擊音效只在 Android 設定。
  - `test/audio_session_test.dart` 會擋住這些錯誤。
- 佛曲在 iOS 用原生 `ios/Runner/ChantLoopPlayer.swift`（AVQueuePlayer + AVPlayerLooper），
  透過 MethodChannel `buddha_counter/chant_loop_player` 與 EventChannel `.../events` 和
  `lib/core/services/ios_loop_chant_engine.dart` 溝通。
  - 原因：以前用 audioplayers 時，循環是「播完通知 Dart → Dart 再叫播放器重播」，iOS 上每次重播會停頓。
    單曲循環**必須由原生端處理**，不要改回在 Dart 收到 complete 後 seek(0) / resume。
  - AVPlayerLooper 不接受檔案時會自動改用「播完跳回開頭」；log 會印 `loop mode: ...` 說明用了哪一種。
  - 外掛在 `ios/Runner/AppDelegate.swift` 的 `didInitializeImplicitFlutterEngine` 裡、
    `GeneratedPluginRegistrant` **之後**註冊。新增 Swift 檔要手動加進 `project.pbxproj`（Runner group 與 Sources phase）。
- iOS 用 **Swift Package Manager**，`ios/` 下沒有 Podfile：**不能用 Podfile `post_install` 去 patch 外掛**。
  要改外掛行為只能換做法（例如自己寫原生 channel）。
- 已知限制：來電等音訊中斷不會通知 Dart。

## Android 音訊

- 佛曲只用一個 audioplayers 播放器 `chant_music_player`，`positionUpdater = null`（進度由 handler 每 250 ms 查詢），
  單曲循環用 `ReleaseMode.loop` 交給 MediaPlayer 原生處理。不要再加「備用播放器接力」。
- 點擊音效是 6 個播放器輪流使用，`AndroidAudioFocus.none`，不會打斷佛曲或其他 App 的音樂。

## 多語言 (i18n)

- 模板是 `lib/l10n/app_zh.arb`（繁中）；三個 ARB（`app_zh`、`app_zh_Hans`、`app_en`）的 key 與 placeholder 必須一致。
  `nullable-getter: false`，少 key 會編譯失敗。
- 改完 ARB 執行 `flutter gen-l10n`，`lib/l10n/generated/` **要一起 commit**
  （`pubspec.yaml` 有 `generate: true`，建置時也會重新產生；commit 是為了讓 analyze、IDE 與 diff 都看得到最新內容）。
- 使用者看得到的文字一律走 `context.l10n`；沒有 BuildContext 的地方（通知、小工具、背景播放）用
  `lookupAppLocalizations(locale)`，語言由 `LocaleController` 推送。曲目名稱與迴向文在 `lib/core/content/`。
- 刻意不翻譯的中文（例如語言名稱「繁體中文」）在同一行加 `// i18n-ignore: <原因>`，否則 CJK 檢查會失敗。
- `tools/check_arb_parity.sh` 內部用 `dart` 執行（不需要 Python）。
- 新增語言時：Android 要有對應的 `res/values-*`（中文已有 `zh`、`zh-rTW/HK/MO/CN/SG`、`b+zh+Hant/Hans`），
  iOS 要加進 `Info.plist` 的 `CFBundleLocalizations` 並建立 `*.lproj`。
- 英文佛教用語已對照公開英譯修訂過一次（尚未經人審閱）；新增或修改前先查並更新 `lib/l10n/GLOSSARY.md`。

## 桌面小工具

- iOS App Group：`group.com.yichung.lee.count4`（另有舊的 `group.app.CountApp`）。
  Sideloadly 等側載工具會把 App Group 改寫成 `group.<實際 bundle id>`，`WidgetService` 會依序嘗試；
  側載版小工具讀不到資料是正常的，以 TestFlight 版為準。
- Android 有兩個 `BuddhaCounterWidgetProvider`（`com.yichung.lee.buddha_counter` 與相容用的
  `com.yichung.lee.count4`），都要保留。

## 版本號

- 只改 `pubspec.yaml` 的 `version: <名稱>+<建置編號>`。
- 建置編號只有在**要上傳 TestFlight / Google Play** 時才 +1（商店要求比上次上傳的大）。
  自己側載測試不用改。

## CI

- 平常 push **不會**觸發建置。`ci_android.yml` 與 `deploy_ios_testflight.yml` 在推送 `v*` tag、發布 Release 或手動時執行；
  `ci_ios.yml`（未簽名 IPA，給側載）只能手動；Codemagic 只能在網頁手動開始。
- repo 是私有的，macOS runner 的分鐘數是 Linux 的 10 倍：iOS workflow 不要設成自動觸發。
- 手動觸發：`gh workflow run ci_ios.yml --ref <branch>`。

## 測試

- 共用 helper 在 `test/helpers/test_app.dart`：
  - `setUpTestPlatformMocks()`：音訊、背景播放、路徑、套件資訊的平台通道 mock，並把語言固定為 zh-TW。
  - `testApp(...)` / `liveLocaleApp(app, home)`：掛好多語言的 MaterialApp（後者跟著 `LocaleController` 切換語言）。
  - `disposeAndSettleTimers(tester)`：畫面裡有 `MarqueeText` 時，測試結束前呼叫，避免 pending timer。
  - `loadRealLatinFont()`：載入 SDK 內附 Roboto 來量真實英文字寬；找不到時回傳 false，測試應略過。
- 測試裡的 log `MissingPluginException(... home_widget)` 與 `scheduleDailyReminder error` 是正常的（沒有原生端）。
- iOS / Android 播放引擎分流用 `debugDefaultTargetPlatformOverride` 測，見 `test/chant_music_engine_test.dart`。

## 其他

- Windows + `core.autocrlf=true`：repo 內是 LF，checkout 是 CRLF；`git add` 時的 CRLF 警告可以忽略。
  用腳本改檔時寫成 LF 即可。
- `ios/secret/` 已被 `.gitignore` 排除，不要把金鑰或憑證加進 repo。
