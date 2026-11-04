import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:buddha_counter/app/app_controllers.dart';
import 'package:buddha_counter/core/constants/chant_songs.dart';
import 'package:buddha_counter/core/services/audio_service.dart';
import 'package:buddha_counter/core/services/chant_audio_handler.dart';
import 'package:buddha_counter/core/services/practice_record_service.dart';
import 'package:buddha_counter/core/services/storage_service.dart';
import 'package:buddha_counter/ui/common/app_toast.dart';
import 'package:buddha_counter/ui/common/marquee_text.dart';
import 'package:buddha_counter/ui/legacy/screens/legacy_about_screen.dart';
import 'package:buddha_counter/ui/legacy/screens/legacy_counter_screen.dart';
import 'package:buddha_counter/ui/legacy/screens/legacy_settings_screen.dart';
import 'package:buddha_counter/ui/modern/screens/modern_counter_screen.dart';
import 'package:buddha_counter/ui/modern/views/modern_counter_view.dart';
import 'package:buddha_counter/ui/modern/views/modern_practice_view.dart';
import 'package:buddha_counter/ui/modern/views/modern_timer_view.dart';
import 'package:buddha_counter/ui/modern/widgets/modern_floating_player.dart';
import 'package:buddha_counter/ui/modern/widgets/modern_guide_dialog.dart';
import 'package:buddha_counter/ui/modern/widgets/song_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpTestPlatformMocks();

  group('BuddhaCounter Storage & Model Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        StorageService.keyCounter: 108,
        StorageService.keyAutoCounter: 250,
        StorageService.keyAutoElapsedSeconds: 60,
        StorageService.keyAutoStopMinutes: 15,
      });
    });

    test('Loads initial counter value from storage', () async {
      final storage = await StorageService.init();
      expect(storage.getCounter(), 108);
      expect(storage.getAutoCounter(), 250);
      expect(storage.getAutoElapsedSeconds(), 60);
      expect(storage.getAutoStopMinutes(), 15);
    });

    test('Updates counter value in storage', () async {
      final storage = await StorageService.init();
      await storage.setCounter(1000);
      expect(storage.getCounter(), 1000);

      await storage.setAutoCounter(500);
      expect(storage.getAutoCounter(), 500);
    });

    test('Default sound effect is woodfish1', () async {
      final storage = await StorageService.init();
      expect(storage.getSoundEffect(), SoundEffectType.woodfish1);
    });

    test('Default UI mode is legacy', () async {
      final storage = await StorageService.init();
      expect(storage.getUiMode(), AppUiMode.legacy);
    });
  });

  group('Chant Songs & Audio Metadata Tests', () {
    test('Contains 31 reordered OGG songs (4-char -> 6-char -> others)', () {
      final songs = ChantConstants.getAllSongs();
      expect(songs.length, 31);

      // 0..10 為四字「阿彌陀佛」開頭
      for (var i = 0; i <= 10; i++) {
        expect(songs[i].title.startsWith('阿彌陀佛'), isTrue);
      }
      // 11..25 為六字「南無阿彌陀佛」開頭
      for (var i = 11; i <= 25; i++) {
        expect(songs[i].title.startsWith('南無阿彌陀佛'), isTrue);
      }
    });

    test(
        'All 31 songs have calibrated beatIntervalMs, ascending markers, and tags',
        () {
      for (final song in ChantConstants.defaultSongs) {
        expect(song.phraseMarkersMs, isNotEmpty);
        expect(song.tags, isNotEmpty);
        for (var i = 1; i < song.phraseMarkersMs.length; i++) {
          expect(song.phraseMarkersMs[i],
              greaterThan(song.phraseMarkersMs[i - 1]));
        }
        final expectedBeatMs =
            (song.phraseMarkersMs.last / song.phraseMarkersMs.length).round();
        expect(song.beatIntervalMs, expectedBeatMs);
      }

      // 驗證省略 beatIntervalMs 時仍可由 phraseMarkersMs 自動推算，並具備預設演出者與專輯
      const customSong = ChantSong(
        id: 99,
        title: '測試佛曲',
        assetPath: 'audio/test.ogg',
        phraseMarkersMs: [4000, 8000],
      );
      expect(customSong.beatIntervalMs, isNull);
      expect(customSong.effectiveBeatIntervalMs, 4000);
      expect(customSong.artist, '三寶弟子');
      expect(customSong.album, '念佛計數器');
      expect(ChantConstants.availableTags, contains(ChantTag.fourCharAmitabha));
      expect(ChantConstants.countSongsByTag(ChantTag.fourCharAmitabha), 12);
    });

    test(
        'loadMetadataFromAssets reads OGG Vorbis title, artist, album with defaults',
        () async {
      await ChantConstants.loadMetadataFromAssets();
      expect(ChantConstants.isMetadataLoaded, isTrue);

      // bb01 音檔內嵌 artist 為「悟道法師」、album 為「念佛計數器」
      final s0 = ChantConstants.getSongById(0);
      expect(s0.title, '阿彌陀佛-四字四音-華藏淨宗-悟道法師');
      expect(s0.artist, '悟道法師');
      expect(s0.album, '念佛計數器');

      // bb02 音檔未設定 artist，應自動套用預設值「三寶弟子」
      final s1 = ChantConstants.getSongById(1);
      expect(s1.title, '阿彌陀佛-四字四音配樂-華藏淨宗');
      expect(s1.artist, '三寶弟子');
      expect(s1.album, '念佛計數器');

      // bb27 正字後內嵌標題為「南無釋迦牟尼佛-朝山聖號-靈巖梵唄-沙彌師父」
      final s26 = ChantConstants.getSongById(26);
      expect(s26.title, '南無釋迦牟尼佛-朝山聖號-靈巖梵唄-沙彌師父');
      expect(s26.artist, '沙彌師父');
      expect(s26.album, '念佛計數器');
    });

    test('AudioService can be created without assertion errors', () {
      expect(AudioService.new, returnsNormally);
    });
  });

  group('Modern Theme & Practice Settings Tests', () {
    test('Storage handles themeMode, targetCount, and vibration', () async {
      final storage = await StorageService.init();
      expect(storage.getThemeMode(), 'light');
      expect(storage.getTargetCount(), 108);
      expect(storage.getVibrationEnabled(), true);

      await storage.setThemeMode('dark');
      expect(storage.getThemeMode(), 'dark');

      await storage.setTargetCount(1080);
      expect(storage.getTargetCount(), 1080);

      await storage.setVibrationEnabled(false);
      expect(storage.getVibrationEnabled(), false);
    });

    test(
        'AppControllers starts auto count cleanly without stale audio beat jumps',
        () async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);

      expect(app.autoCount.isCounting, false);
      app.practice.resetAutoCount();
      expect(app.practice.autoCount, 0);

      // 啟動自動計數
      app.autoCount.start();
      expect(app.autoCount.isCounting, true);
      // 確保一開始不會立刻累加舊在途節拍
      expect(app.practice.autoCount, 0);

      app.autoCount.stop();
      expect(app.autoCount.isCounting, false);
    });

    test('Phrase markers and scrubbing seek prevent count miscalculation',
        () async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);

      app.practice.resetAutoCount();
      expect(app.practice.autoCount, 0);

      // 模擬手動拖動進度條
      app.playback.beginScrubbing();
      expect(app.playback.isScrubbing, true);

      // 放開進度條跳至 25 秒
      app.playback.endScrubbing(const Duration(seconds: 25));
      expect(app.playback.isScrubbing, false);
      expect(app.playback.position, const Duration(seconds: 25));

      // 驗證跳轉未造成次數暴增或亂加
      expect(app.practice.autoCount, 0);
    });

    test('Separated resetAutoCount and resetAutoTimer work independently',
        () async {
      final storage = await StorageService.init();
      final audio = AudioService();

      // 模擬有計數與計時數值
      await storage.setAutoCounter(50);
      await storage.setAutoElapsedSeconds(120);
      final app2 = AppControllers.create(storage: storage, audio: audio);

      expect(app2.practice.autoCount, 50);
      expect(app2.autoCount.elapsedSeconds, 120);

      // 僅重置計時 -> 計數應保持 50，計時歸 0
      app2.autoCount.resetElapsed();
      expect(app2.practice.autoCount, 50);
      expect(app2.autoCount.elapsedSeconds, 0);

      // 僅重置計數 -> 計數歸 0，計時不受影響
      await storage.setAutoElapsedSeconds(180);
      final app3 = AppControllers.create(storage: storage, audio: audio);
      expect(app3.practice.autoCount, 50);
      expect(app3.autoCount.elapsedSeconds, 180);

      app3.practice.resetAutoCount();
      expect(app3.practice.autoCount, 0);
      expect(app3.autoCount.elapsedSeconds, 180);
    });

    testWidgets('MarqueeText renders text cleanly', (tester) async {
      await tester.pumpWidget(
        testApp(
          home: const Scaffold(
            body: MarqueeText(text: '南無本師釋迦牟尼佛 (三稱、開經偈)'),
          ),
        ),
      );
      expect(find.text('南無本師釋迦牟尼佛 (三稱、開經偈)'), findsOneWidget);
    });

    testWidgets(
        'ModernCounterView renders and updates without ListTile warnings',
        (tester) async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);

      await tester.pumpWidget(
        app.provide(
          child: testApp(
            home: const Scaffold(
              body: ModernCounterView(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Trigger rebuilds (increment count)
      app.practice.resetCount();
      app.practice.increment();
      await tester.pump();
      expect(app.practice.count, 1);

      // Verify toggle vibration and fullscreen
      app.settings.setVibrationEnabled(false);
      app.settings.setFullscreenTap(true);
      await tester.pump();
    });

    testWidgets(
        'ModernTimerView renders clean Zen disc without spinning progress ring',
        (tester) async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);
      app.autoCount.clearStopCondition();

      await tester.pumpWidget(
        app.provide(
          child: testApp(
            home: const Scaffold(
              body: ModernTimerView(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify clean Zen disc contains auto count number
      expect(find.text(app.practice.autoCount.toString()), findsOneWidget);
      expect(find.text('聲 · 遍'), findsOneWidget);
      // 持續播放 (無停止條件) 時不顯示進度環
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // 設定停止條件後顯示「靜態」進度環 (有明確 value，絕非無限轉圈動畫)
      app.autoCount.setTargetCount(108);
      await tester.pump();
      final ring = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator));
      expect(ring.value, isNotNull);
      app.autoCount.clearStopCondition();
    });

    test('AudioService starts in single-song loop mode', () {
      expect(AudioService().releaseMode, ReleaseMode.loop);
    });

    testWidgets('AppToast renders message correctly and dismisses',
        (tester) async {
      await tester.pumpWidget(
        testApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => AppToast.show(ctx, '測試快顯通知'),
                child: const Text('點擊'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('點擊'));
      await tester.pump();
      expect(find.text('測試快顯通知'), findsOneWidget);

      // SnackBar 入場動畫 (約 250ms)
      await tester.pump(const Duration(milliseconds: 300));
      // 等待 SnackBar 顯示時長 (400ms) 結束
      await tester.pump(const Duration(milliseconds: 500));
      // 等待退場動畫完成
      await tester.pumpAndSettle();
      expect(find.text('測試快顯通知'), findsNothing);
    });
  });

  group('Auto-Count 3-Component Synchronization Tests', () {
    test(
        'isInAutoCountMode accurately reflects active tab, legacy screen, or active count',
        () async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);

      // 現代模式預設第 0 頁 (手動計數)
      app.settings.setUiMode(AppUiMode.modern);
      app.autoCount.setScreenVisible(false);
      expect(app.autoCount.handlesPlayback, isFalse);

      // 切換至第 1 頁 (自動計數)
      app.autoCount.setScreenVisible(true);
      expect(app.autoCount.handlesPlayback, isTrue);

      // 切換至第 2 頁 (迴向)
      app.autoCount.setScreenVisible(false);
      expect(app.autoCount.handlesPlayback, isFalse);

      // 切換至經典模式
      app.settings.setUiMode(AppUiMode.legacy);
      expect(app.autoCount.handlesPlayback, isFalse);
      app.autoCount.setScreenVisible(true);
      expect(app.autoCount.handlesPlayback, isTrue);
      app.autoCount.setScreenVisible(false);
      expect(app.autoCount.handlesPlayback, isFalse);
    });

    testWidgets(
        'Component 1 (toggleChant) toggles auto-count when in auto-count mode',
        (tester) async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);

      app.settings.setUiMode(AppUiMode.modern);
      app.autoCount.setScreenVisible(true); // 自動計數頁
      expect(app.autoCount.isCounting, isFalse);
      expect(app.playback.isPlaying, isFalse);

      // 點擊元件 1 的播放
      app.playback.toggleChant(app.playback.currentSongId);
      expect(app.autoCount.isCounting, isTrue);
      expect(app.playback.isPlaying, isTrue);

      // 點擊元件 1 的暫停：必須連動暫停自動計數
      app.playback.toggleChant(app.playback.currentSongId);
      expect(app.autoCount.isCounting, isFalse);
      expect(app.playback.isPlaying, isFalse);

      // 點擊元件 2/3 (toggleAutoCount) 的開始：連動啟動
      app.autoCount.toggle();
      expect(app.autoCount.isCounting, isTrue);
      expect(app.playback.isPlaying, isTrue);

      // 再次點擊元件 1 的暫停：同步暫停
      app.playback.toggleChant(app.playback.currentSongId);
      expect(app.autoCount.isCounting, isFalse);
      expect(app.playback.isPlaying, isFalse);
      app.dispose();
    });

    testWidgets(
        'Component 1 (toggleChant) only plays background music when NOT in auto-count mode',
        (tester) async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);

      app.settings.setUiMode(AppUiMode.modern);
      app.autoCount.setScreenVisible(false); // 手動計數頁 (非自動計數)
      expect(app.autoCount.isCounting, isFalse);
      expect(app.playback.isPlaying, isFalse);

      // 點擊元件 1 的播放
      app.playback.toggleChant(app.playback.currentSongId);
      // 音樂有在播放，但自動計數絕不會啟動
      expect(app.playback.isPlaying, isTrue);
      expect(app.autoCount.isCounting, isFalse);

      // 點擊元件 1 的暫停
      app.playback.toggleChant(app.playback.currentSongId);
      expect(app.playback.isPlaying, isFalse);
      expect(app.autoCount.isCounting, isFalse);
      app.dispose();
    });

    testWidgets(
        'UI Sync: Component 1, Component 2, and Component 3 stay 100% in sync',
        (tester) async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);

      app.settings.setUiMode(AppUiMode.modern);
      app.autoCount.setScreenVisible(true); // 位於自動計數頁

      await tester.pumpWidget(
        app.provide(
          child: testApp(
            home: const Scaffold(
              body: Column(
                children: [
                  Expanded(child: ModernTimerView()),
                  ModernFloatingPlayer(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // 初始狀態：皆為「開始」/「播放」
      expect(find.text('開始'), findsOneWidget); // 元件 2 按鈕
      expect(find.byTooltip('開始'), findsOneWidget); // 元件 3 碼表按鈕
      expect(find.byTooltip('播放'), findsOneWidget); // 元件 1 播放器按鈕

      // 1. 透過【元件 1 (播放器)】點擊播放
      await tester.tap(find.byTooltip('播放'));
      await tester.pump();

      // 驗證 1、2、3 全部同步轉為「暫停」狀態
      expect(find.text('暫停'), findsOneWidget); // 元件 2 按鈕
      expect(find.byTooltip('暫停'),
          findsNWidgets(2)); // 元件 1 與元件 3 兩者 tooltip 皆為「暫停」
      expect(app.autoCount.isCounting, isTrue);
      expect(app.playback.isPlaying, isTrue);

      // 2. 透過【元件 2 (中間大按鈕)】點擊暫停
      await tester.tap(find.text('暫停'));
      await tester.pump();

      // 驗證 1、2、3 全部同步回到「開始」/「播放」狀態
      expect(find.text('開始'), findsOneWidget); // 元件 2
      expect(find.byTooltip('開始'), findsOneWidget); // 元件 3
      expect(find.byTooltip('播放'), findsOneWidget); // 元件 1
      expect(app.autoCount.isCounting, isFalse);
      expect(app.playback.isPlaying, isFalse);

      // 3. 透過【元件 3 (碼表按鈕)】點擊開始
      await tester.tap(find.byTooltip('開始'));
      await tester.pump();

      // 驗證 1、2、3 再次全部同步轉為「暫停」狀態
      expect(find.text('暫停'), findsOneWidget);
      expect(find.byTooltip('暫停'), findsNWidgets(2));
      expect(app.autoCount.isCounting, isTrue);
      expect(app.playback.isPlaying, isTrue);

      // 4. 再次透過【元件 1 (播放器)】點擊暫停
      await tester.tap(find.byTooltip('暫停').last);
      await tester.pump();

      // 驗證 1、2、3 再次全部同步回到「開始」/「播放」狀態
      expect(find.text('開始'), findsOneWidget);
      expect(find.byTooltip('開始'), findsOneWidget);
      expect(find.byTooltip('播放'), findsOneWidget);
      expect(app.autoCount.isCounting, isFalse);
      expect(app.playback.isPlaying, isFalse);
    });
  });

  group('Custom Timer & Orientation Lock Tests', () {
    testWidgets('Custom stop minutes picker allows setting arbitrary minutes',
        (tester) async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);

      await tester.pumpWidget(
        app.provide(
          child: testApp(
            home: const Scaffold(
              body: ModernTimerView(),
            ),
          ),
        ),
      );
      await tester.pump();

      // 先設定聲數目標，驗證之後設定定時會將其清空 (二擇一)
      app.autoCount.setTargetCount(500);
      await tester.pump();
      expect(find.text('目標 500'), findsOneWidget);

      // 點擊自動停止設定按鈕打開 BottomSheet
      await tester.tap(find.text('目標 500'));
      await tester.pumpAndSettle();

      expect(find.text('設定自動停止'), findsOneWidget);
      expect(find.text('念滿聲數停止'), findsOneWidget);
      expect(find.text('定時停止'), findsOneWidget);

      // 於定時停止區塊 (第二個輸入框) 輸入自訂分鐘數 25
      final minutesField = find.byType(TextField).last;
      await tester.ensureVisible(minutesField);
      await tester.enterText(minutesField, '25');
      await tester.pump();

      // 點擊定時區塊的「設定」按鈕
      final setBtn = find.widgetWithText(FilledButton, '設定').last;
      await tester.ensureVisible(setBtn);
      await tester.tap(setBtn);
      await tester.pumpAndSettle();

      // 驗證 ViewModel 與外層按鈕顯示已更新為 25 分鐘，且聲數目標被清空
      expect(app.autoCount.stopMinutes, 25);
      expect(app.autoCount.targetCount, 0);
      expect(find.text('定時 25 分'), findsOneWidget);
    });

    test('Orientation lock toggles and updates StorageService', () async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);

      expect(app.settings.isOrientationLocked, isFalse);
      expect(storage.getOrientationLocked(), isFalse);

      app.settings.toggleOrientationLock();
      expect(app.settings.isOrientationLocked, isTrue);
      expect(storage.getOrientationLocked(), isTrue);

      app.settings.toggleOrientationLock();
      expect(app.settings.isOrientationLocked, isFalse);
      expect(storage.getOrientationLocked(), isFalse);
    });

    testWidgets('ModernCounterScreen AppBar contains orientation lock button',
        (tester) async {
      final storage = await StorageService.init();
      await storage.setOrientationLocked(false);
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);

      await tester.pumpWidget(
        app.provide(
          child: testApp(
            home: const ModernCounterScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byTooltip('鎖定螢幕方向'), findsOneWidget);

      // 點擊方向鎖定按鈕
      await tester.tap(find.byTooltip('鎖定螢幕方向'));
      await tester.pumpAndSettle();
      expect(app.settings.isOrientationLocked, isTrue);
      expect(find.byTooltip('解除方向鎖定'), findsOneWidget);
    });

    testWidgets('LegacyCounterScreen AppBar contains orientation lock button',
        (tester) async {
      final storage = await StorageService.init();
      await storage.setOrientationLocked(false);
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);

      await tester.pumpWidget(
        app.provide(
          child: testApp(
            home: const LegacyCounterScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byTooltip('鎖定螢幕方向'), findsOneWidget);

      await tester.tap(find.byTooltip('鎖定螢幕方向'));
      await tester.pumpAndSettle();
      expect(app.settings.isOrientationLocked, isTrue);
      expect(find.byTooltip('解除方向鎖定'), findsOneWidget);
    });

    testWidgets(
        'AppBar contains screen awake button that toggles keep screen on',
        (tester) async {
      final storage = await StorageService.init();
      await storage.setKeepScreenOn(false);
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);

      await tester.pumpWidget(
        app.provide(
          child: testApp(
            home: const ModernCounterScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byTooltip('螢幕常亮'), findsOneWidget);

      // 點擊切換螢幕常亮
      await tester.tap(find.byTooltip('螢幕常亮'));
      await tester.pumpAndSettle();
      expect(app.settings.keepScreenOn, isTrue);
      expect(find.byTooltip('關閉螢幕常亮'), findsOneWidget);
    });

    testWidgets(
        'ModernPracticeView renders Buddha image and swipeable HuiXiang verses',
        (tester) async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);
      await app.settings.setHuiXiangIndex(0);

      await tester.pumpWidget(
        app.provide(
          child: testApp(
            home: const Scaffold(
              body: ModernPracticeView(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      // 驗證阿彌陀佛聖像、大回向西方文標題與偈頌文句
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('大回向西方文'), findsOneWidget);
      expect(find.text('願我臨終無障礙 阿彌陀佛遠相迎'), findsOneWidget);
      expect(find.text('南無阿彌陀佛'), findsOneWidget);

      // 向左滑動切換至第二則迴向文（回向偈）
      await tester.fling(
        find.text('大回向西方文'),
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(app.settings.huiXiangIndex, 1);
      expect(find.text('回向偈'), findsOneWidget);
      expect(find.text('願生西方淨土中 九品蓮花為父母'), findsOneWidget);

      // 向右滑動切回第一則迴向文（大回向西方文）
      await tester.fling(
        find.text('回向偈'),
        const Offset(300, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(app.settings.huiXiangIndex, 0);
      expect(find.text('大回向西方文'), findsOneWidget);
    });

    test('timed stop progress and remaining seconds', () async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);
      app.autoCount.resetElapsed();

      // 未設定定時停止
      app.autoCount.setStopMinutes(0);
      expect(app.autoCount.stopElapsedProgress, 0.0);
      expect(app.autoCount.stopRemainingSeconds, 0);

      // 設定 10 分鐘、尚未開始計時
      app.autoCount.setStopMinutes(10);
      expect(app.autoCount.stopElapsedProgress, 0.0);
      expect(app.autoCount.stopRemainingSeconds, 600);
    });

    testWidgets(
        'LegacyCounterScreen central button displays count and increments when tapped',
        (tester) async {
      final storage = await StorageService.init();
      await storage.setOrientationLocked(false);
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);
      app.practice.resetCount();

      await tester.pumpWidget(
        app.provide(
          child: testApp(
            home: const LegacyCounterScreen(),
          ),
        ),
      );
      await tester.pump();

      // 中央按鈕顯示初始計數 0
      expect(find.widgetWithText(ElevatedButton, '0'), findsOneWidget);

      // 點擊中央按鈕
      await tester.tap(find.widgetWithText(ElevatedButton, '0'));
      await tester.pump();

      // 數字遞增為 1
      expect(app.practice.count, 1);
      expect(find.widgetWithText(ElevatedButton, '1'), findsOneWidget);
    });

    testWidgets('LegacySettingsScreen contains unified screen awake switch',
        (tester) async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);
      app.settings.setKeepScreenOn(false);

      await tester.pumpWidget(
        app.provide(
          child: testApp(
            home: const LegacySettingsScreen(),
          ),
        ),
      );
      await tester.pump();

      // 驗證含有保持螢幕常亮開關
      expect(find.text('保持螢幕常亮（防止休眠）'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);

      // 點擊開關
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(app.settings.keepScreenOn, isTrue);
    });

    testWidgets(
        'LegacyAboutScreen displays dynamic project version from PackageInfo',
        (tester) async {
      await tester.pumpWidget(
        testApp(
          home: const LegacyAboutScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 驗證動態顯示專案版本號 1.48.0
      expect(find.text('版本 1.48.0'), findsOneWidget);
      // 驗證隱私權政策按鈕存在 (iOS 與 Android 雙版本)
      expect(find.text('iOS 隱私權政策'), findsOneWidget);
      expect(find.text('Android 隱私權政策'), findsOneWidget);
    });

    test('Storage handles seenModernGuide flag and ViewModel updates',
        () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);

      expect(storage.getSeenModernGuide(), isFalse);
      expect(app.settings.hasSeenModernGuide, isFalse);

      await app.settings.markModernGuideSeen();
      expect(storage.getSeenModernGuide(), isTrue);
      expect(app.settings.hasSeenModernGuide, isTrue);
    });

    testWidgets('ModernCounterView allows setting custom target count',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);

      await tester.pumpWidget(
        app.provide(
          child: testApp(
            home: const Scaffold(
              body: ModernCounterView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 點擊功課目標按鈕開啟設定面板
      await tester.tap(find.text('目標 108'));
      await tester.pumpAndSettle();

      // 驗證底部對話框出現
      expect(find.text('設定手動計數目標'), findsOneWidget);
      expect(find.text('或自訂目標聲數：'), findsOneWidget);

      // 輸入自訂目標 888 聲
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, '888');
      await tester.pump();

      // 點擊「設定」按鈕
      await tester.tap(find.widgetWithText(FilledButton, '設定'));
      await tester.pumpAndSettle();

      // 驗證目標已更新為 888
      expect(app.practice.targetCount, 888);
      expect(find.text('目標 888'), findsOneWidget);

      // 再次開啟設定面板，驗證自訂標籤出現
      await tester.tap(find.text('目標 888'));
      await tester.pumpAndSettle();
      expect(find.text('888(自訂)'), findsOneWidget);

      // 關閉面板
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
    });

    testWidgets('ModernGuideDialog renders single page summary and dismisses',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);

      await tester.pumpWidget(
        app.provide(
          child: testApp(
            home: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ModernGuideDialog.show(ctx),
                child: const Text('開啟導覽'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 點擊開啟導覽
      await tester.tap(find.text('開啟導覽'));
      await tester.pumpAndSettle();

      // 驗證已標記已讀
      expect(app.settings.hasSeenModernGuide, isTrue);

      // 驗證一頁式重點內容
      expect(find.text('全新功能特色'), findsOneWidget);
      expect(find.text('念佛與自動計數'), findsOneWidget);
      expect(find.text('每日功課表記'), findsOneWidget);
      expect(find.text('桌面小工具與定時提醒'), findsOneWidget);
      expect(find.text('開始精進'), findsOneWidget);

      // 點擊「開始精進」按鈕關閉
      await tester.tap(find.text('開始精進'));
      await tester.pumpAndSettle();

      // 對話框已關閉
      expect(find.text('全新功能特色'), findsNothing);
    });

    test(
        'AudioService handles rapid overlapping click sound effects via player pool',
        () async {
      final audio = AudioService();

      // 連續快速敲擊木魚（超過池容量 6，驗證輪詢循環與無死鎖/崩潰）
      for (int i = 0; i < 4; i++) {
        await audio.playClickSfx(SoundEffectType.woodfish1);
        await audio.playClickSfx(SoundEffectType.woodfish2);
      }

      // 連續敲擊引磬
      for (int i = 0; i < 4; i++) {
        await audio.playClickSfx(SoundEffectType.bell);
      }

      // 靜音模式不播放
      await audio.playClickSfx(SoundEffectType.none);

      // 釋放資源
      expect(audio.dispose, returnsNormally);
    });

    testWidgets(
        'Unified player bottom sheet expands on swipe/tap to reveal tag-filtered song menu',
        (tester) async {
      // 模擬 Pixel 7 直向螢幕比例 (412 x 915)，驗證收合時無大面積空白區域
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final storage = await StorageService.init();
      await storage.setSeenModernGuide(true);
      await storage.setUiMode(AppUiMode.modern);
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);

      await tester.pumpWidget(
        app.provide(
          child: testApp(
            home: const ModernCounterScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // 點擊下方小型播放器彈出下半部音樂播控面板
      ModernFloatingPlayer.openExpandedPlayer(
        tester.element(find.byType(ModernFloatingPlayer)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      final cueFinder = find.text('上滑展開佛曲選單（共 31 首）');
      expect(cueFinder, findsOneWidget);

      // 驗證播控主按鈕與上滑提示之間緊湊無大面積空白
      final playRect = tester.getRect(find.byIcon(Icons.play_arrow_rounded));
      final cueRect = tester.getRect(cueFinder);
      expect(cueRect.top - playRect.bottom, lessThan(40.0));
      expect(cueRect.bottom, lessThanOrEqualTo(915.0));

      // 往上滑動同一個面板，無縫展開標籤分類選單
      await tester.drag(
        cueFinder,
        const Offset(0, -340),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('佛曲選單（共 31 首） · 點擊收合'), findsOneWidget);
      final tagLabel =
          '朝山聖號 (${ChantConstants.countSongsByTag(ChantTag.pilgrimage)})';
      expect(find.text(tagLabel), findsOneWidget);

      // 點擊「朝山聖號」標籤進行分類篩選
      await tester.ensureVisible(find.text(tagLabel));
      await tester.tap(find.text(tagLabel));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('朝山聖號'), findsWidgets);

      // 點擊置頂收合按鈕回下半部音樂播放器
      await tester.tap(find.byTooltip('收合回播放器'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('上滑展開佛曲選單（共 31 首）'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets(
        'Selecting songs in song list never triggers microtask ping-pong loop in Manual or Auto-Count mode',
        (tester) async {
      final storage = await StorageService.init();
      await storage.setSeenModernGuide(true);
      await storage.setUiMode(AppUiMode.modern);
      final countingHandler = _CountingAudioHandler();
      final audio = AudioService(handler: countingHandler);
      final app = AppControllers.create(storage: storage, audio: audio);

      // 1. 現代模式【自動計數】分頁：點擊佛曲（無論尚未開始或正在計數中）皆只呼叫一次 playSong，絕不陷入無限微任務迴圈
      app.settings.setUiMode(AppUiMode.modern);
      app.autoCount.setScreenVisible(true);
      app.playback.selectAndPlaySong(11); // #12 南無阿彌陀佛-思鄉佛號
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(countingHandler.playSongCalls, 1);
      expect(app.playback.currentSongId, 11);
      expect(app.autoCount.isCounting, isTrue);
      expect(app.playback.isPlaying, isTrue);

      // 自動計數進行中再次點擊另一首佛曲（#28 南無地藏王菩薩）
      app.playback.selectAndPlaySong(27);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(countingHandler.playSongCalls, 2);
      expect(app.playback.currentSongId, 27);
      expect(app.autoCount.isCounting, isTrue);
      expect(app.playback.isPlaying, isTrue);

      // 透過 toggleChant 點擊另一首不同佛曲（#05）應直接切換播放而非誤暫停
      app.playback.toggleChant(4);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(countingHandler.playSongCalls, 3);
      expect(app.playback.currentSongId, 4);
      expect(app.autoCount.isCounting, isTrue);
      expect(app.playback.isPlaying, isTrue);

      // 停止後切回【手動計數】分頁並實際在展開的佛曲清單 UI 中點擊曲目
      app.autoCount.stop();
      await tester.pump();
      app.autoCount.setScreenVisible(false);

      await tester.pumpWidget(
        app.provide(
          child: testApp(
            home: const ModernCounterScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      ModernFloatingPlayer.openSongPicker(
        tester.element(find.byType(ModernFloatingPlayer)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.byType(SongListTile).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(countingHandler.playSongCalls, 4);
      expect(app.playback.currentSongId, 0);
      expect(app.playback.isPlaying, isTrue);
      expect(app.autoCount.isCounting, isFalse);

      app.playback.stop();
      app.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets(
        'Directly selecting song from stopped state properly starts playback and populates duration/position streams',
        (tester) async {
      final storage = await StorageService.init();
      final handler = _CountingAudioHandler();
      final audio = AudioService(handler: handler);
      final app = AppControllers.create(storage: storage, audio: audio);

      app.settings.setUiMode(AppUiMode.modern);
      app.autoCount.setScreenVisible(false);
      expect(app.playback.isPlaying, isFalse);

      app.playback.selectAndPlaySong(3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(app.playback.isPlaying, isTrue);
      expect(app.playback.currentSongId, 3);
      expect(handler.playSongCalls, 1);

      app.playback.stop();
      app.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('Daily Practice Records, Calendar & Habit Widget Tests', () {
    test(
        'PracticeRecordService correctly tracks daily records, manual and auto counts',
        () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final records = PracticeRecordService(storage);

      final date = DateTime(2026, 10, 30);
      expect(records.getCount(date), 0);

      await records.addCount(date, manual: 108);
      expect(records.getCount(date), 108);
      expect(records.getRecord(date).manualCount, 108);
      expect(records.getRecord(date).autoCount, 0);

      await records.addCount(date, auto: 200);
      expect(records.getCount(date), 308);
      expect(records.getRecord(date).autoCount, 200);

      // 手動直接修改自由度
      await records.setCount(date, 1000);
      expect(records.getCount(date), 1000);

      // 自由增減 (+108, -200)
      await records.adjustCount(date, 108);
      expect(records.getCount(date), 1108);

      await records.adjustCount(date, -200);
      expect(records.getCount(date), 908);

      // 清空紀錄
      await records.clearDate(date);
      expect(records.getCount(date), 0);
    });

    test(
        'PracticeRecordService calculates weekly, monthly and Duolingo streak accurately',
        () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final records = PracticeRecordService(storage);

      final baseDate = DateTime(2026, 10, 30); // Friday
      await records.setCount(DateTime(2026, 10, 26), 100); // Monday
      await records.setCount(DateTime(2026, 10, 27), 200); // Tuesday
      await records.setCount(DateTime(2026, 10, 28), 300); // Wednesday
      await records.setCount(DateTime(2026, 10, 29), 400); // Thursday
      await records.setCount(DateTime(2026, 10, 30), 500); // Friday

      // 本週累計 (100+200+300+400+500 = 1500)
      expect(records.getWeeklyTotal(baseDate), 1500);

      // 本月累計 (1500)
      expect(records.getMonthlyTotal(2026, 10), 1500);

      // 連續天數 (26, 27, 28, 29, 30 -> 5 天)
      expect(records.calculateStreak(baseDate), 5);

      // 若週六 (31) 尚未念佛，但週五有念佛，連續天數延續 (5 天)
      final saturday = DateTime(2026, 10, 31);
      expect(records.calculateStreak(saturday), 5);

      // 週日 (11/1) 若仍未念佛且週六為 0，則中斷為 0
      final sunday = DateTime(2026, 11, 1);
      expect(records.calculateStreak(sunday), 0);
    });

    test(
        'AppControllers increments and manual edits synchronize with practice records',
        () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);

      final today = DateTime.now();
      expect(app.practice.todayPracticeCount, 0);

      app.practice.increment();
      expect(app.practice.count, 1);
      expect(app.practice.todayPracticeCount, 1);

      app.practice.increment();
      expect(app.practice.count, 2);
      expect(app.practice.todayPracticeCount, 2);

      app.practice.decrement();
      expect(app.practice.count, 1);
      expect(app.practice.todayPracticeCount, 1);

      // 透過 ViewModel 自由調整功課
      await app.practice.adjustPracticeCount(today, 107);
      expect(app.practice.count, 108);
      expect(app.practice.todayPracticeCount, 108);

      // 直接修改數值
      await app.practice.setPracticeCount(today, 1000);
      expect(app.practice.count, 1000);
      expect(app.practice.todayPracticeCount, 1000);

      // 每日提醒設定
      await app.practice
          .updateReminderSettings(enabled: true, hour: 21, minute: 30);
      expect(app.practice.isReminderEnabled, isTrue);
      expect(app.practice.reminderHour, 21);
      expect(app.practice.reminderMinute, 30);
    });

    test(
        'AppControllers resets counts to 0 across midnight rollover while preserving yesterday records',
        () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayKey = PracticeRecordService.formatDateKey(yesterday);
      final todayKey = PracticeRecordService.formatDateKey(now);

      // 模擬昨日操作後儲存的數據
      SharedPreferences.setMockInitialValues({
        StorageService.keyCounter: 500,
        StorageService.keyAutoCounter: 200,
        StorageService.keyLastActiveDate: yesterdayKey,
        StorageService.keyDailyRecords: jsonEncode({
          yesterdayKey: {
            'manual': 500,
            'auto': 200,
            'total': 700,
          }
        }),
      });

      final storage = await StorageService.init();
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);

      // 驗證跨日初始化後：今日計數自動歸零，昨日功課完整保留於月曆中
      expect(app.practice.count, 0);
      expect(app.practice.autoCount, 0);
      expect(app.practice.todayPracticeCount, 0);
      expect(app.practice.records.getCount(yesterday), 700);
      expect(app.practice.records.getRecord(yesterday).manualCount, 500);
      expect(app.practice.records.getRecord(yesterday).autoCount, 200);

      // 今日開始念佛 1 聲
      app.practice.increment();
      expect(app.practice.count, 1);
      expect(app.practice.todayPracticeCount, 1);
      // 昨日紀錄絲毫不受影響
      expect(app.practice.records.getCount(yesterday), 700);
      expect(storage.getLastActiveDate(), todayKey);
    });

    test(
        'AppControllers self-heals if yesterday counts were accidentally duplicated into today record',
        () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayKey = PracticeRecordService.formatDateKey(yesterday);
      final todayKey = PracticeRecordService.formatDateKey(now);

      // 模擬舊版初始化 bug：昨日計數被複製播種進了今日記錄
      SharedPreferences.setMockInitialValues({
        StorageService.keyCounter: 888,
        StorageService.keyAutoCounter: 0,
        StorageService.keyLastActiveDate: yesterdayKey,
        StorageService.keyDailyRecords: jsonEncode({
          yesterdayKey: {
            'manual': 888,
            'auto': 0,
            'total': 888,
          },
          todayKey: {
            'manual': 888,
            'auto': 0,
            'total': 888,
          }
        }),
      });

      final storage = await StorageService.init();
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);

      // 驗證自我修復機制：成功偵測到舊版污染並將今日歸零，昨日記錄完好
      expect(app.practice.count, 0);
      expect(app.practice.todayPracticeCount, 0);
      expect(app.practice.records.getCount(yesterday), 888);
    });

    testWidgets(
        'ModernCounterScreen includes 4th tab 功課月曆 and renders ModernCalendarView',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final audio = AudioService();
      final app = AppControllers.create(storage: storage, audio: audio);
      app.settings.markModernGuideSeen(); // 防止導覽對話框遮擋

      await tester.pumpWidget(
        app.provide(
          child: testApp(
            home: const ModernCounterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 驗證底部導覽列包含 4 個項目：手動計數、自動計數、迴向、功課月曆
      expect(find.text('手動計數'), findsWidgets);
      expect(find.text('自動計數'), findsWidgets);
      expect(find.text('迴向'), findsWidgets);
      expect(find.text('功課月曆'), findsOneWidget);

      // 點擊最右邊第 4 個分頁「功課月曆」
      await tester.tap(find.text('功課月曆'));
      await tester.pumpAndSettle();

      // 驗證畫面切換為月曆視圖與統計指標
      expect(find.text('今日功課'), findsOneWidget);
      expect(find.text('本週累計'), findsOneWidget);
      expect(find.text('本月累計'), findsOneWidget);
      expect(find.text('快速增減修訂：'), findsNothing);

      // 點擊「修改數值」按鈕彈出對話框
      final editBtn = find.text('修改數值');
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      expect(find.text('手動修改功課聲數'), findsOneWidget);
      expect(find.text('確認儲存'), findsOneWidget);

      // 輸入自訂聲數 500
      await tester.enterText(find.byType(TextField), '500');
      await tester.tap(find.text('確認儲存'));
      await tester.pumpAndSettle();

      expect(app.practice.todayPracticeCount, 500);
      expect(find.text('500'), findsWidgets);

      // 點擊年月標頭彈出年月選擇器
      final now = DateTime.now();
      final headerFinder = find.text('${now.year} 年 ${now.month} 月');
      expect(headerFinder, findsOneWidget);
      await tester.tap(headerFinder);
      await tester.pumpAndSettle();

      // 驗證彈出年月九宮格對話框
      expect(find.text('回到本月'), findsOneWidget);
      expect(find.text('1 月'), findsOneWidget);
      expect(find.text('12 月'), findsOneWidget);

      // 點擊「1 月」跳轉至 1 月
      await tester.tap(find.text('1 月'));
      await tester.pumpAndSettle();

      expect(find.text('${now.year} 年 1 月'), findsOneWidget);

      // 驗證立即同步桌面小工具按鈕並點擊
      final syncWidgetBtn = find.text('立即同步桌面小工具');
      expect(syncWidgetBtn, findsOneWidget);
      await tester.tap(syncWidgetBtn);
      await tester.pumpAndSettle();
    });
  });

  group('Independent Manual / Auto / Daily Goals Tests', () {
    test('Daily goal inherits legacy target once, then stays independent',
        () async {
      SharedPreferences.setMockInitialValues({
        StorageService.keyTargetCount: 500,
      });
      final storage = await StorageService.init();

      // 舊版升級：首次讀取沿用原目標並寫回
      expect(storage.getDailyTargetCount(), 500);
      expect(storage.getAutoTargetCount(), 0);

      // 之後修改手動目標不會連動每日目標
      await storage.setTargetCount(108);
      expect(storage.getDailyTargetCount(), 500);

      await storage.setDailyTargetCount(1000);
      expect(storage.getTargetCount(), 108);
      expect(storage.getDailyTargetCount(), 1000);
    });

    test('ViewModel exposes separate manual, auto, and daily goals', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final app =
          AppControllers.create(storage: storage, audio: AudioService());

      app.practice.setTargetCount(300);
      app.practice.setDailyTargetCount(2000);
      app.autoCount.setTargetCount(50);

      expect(app.practice.targetCount, 300);
      expect(app.practice.dailyTargetCount, 2000);
      expect(app.autoCount.targetCount, 50);
      expect(storage.getTargetCount(), 300);
      expect(storage.getDailyTargetCount(), 2000);
      expect(storage.getAutoTargetCount(), 50);
    });

    test('Auto count goal and timed stop are mutually exclusive', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final app =
          AppControllers.create(storage: storage, audio: AudioService());

      app.autoCount.setTargetCount(108);
      expect(app.autoCount.targetCount, 108);
      expect(app.autoCount.stopMinutes, 0);

      // 設定定時 -> 聲數目標被清空
      app.autoCount.setStopMinutes(30);
      expect(app.autoCount.stopMinutes, 30);
      expect(app.autoCount.targetCount, 0);
      expect(storage.getAutoTargetCount(), 0);

      // 設定聲數 -> 定時被清空
      app.autoCount.setTargetCount(1000);
      expect(app.autoCount.targetCount, 1000);
      expect(app.autoCount.stopMinutes, 0);
      expect(storage.getAutoStopMinutes(), 0);

      // 清除 -> 兩者皆為 0 (持續播放)
      app.autoCount.clearStopCondition();
      expect(app.autoCount.targetCount, 0);
      expect(app.autoCount.stopMinutes, 0);
    });

    test('Conflicting stored stop settings resolve to timed stop on load',
        () async {
      SharedPreferences.setMockInitialValues({
        StorageService.keyAutoTargetCount: 108,
        StorageService.keyAutoStopMinutes: 20,
      });
      final storage = await StorageService.init();
      final app =
          AppControllers.create(storage: storage, audio: AudioService());
      expect(app.autoCount.stopMinutes, 20);
      expect(app.autoCount.targetCount, 0);
    });

    test('Auto target progress and time progress getters', () async {
      SharedPreferences.setMockInitialValues({
        StorageService.keyAutoCounter: 54,
        StorageService.keyAutoElapsedSeconds: 300,
      });
      final storage = await StorageService.init();
      final app =
          AppControllers.create(storage: storage, audio: AudioService());

      app.autoCount.setTargetCount(108);
      expect(app.autoCount.targetProgress, closeTo(0.5, 1e-9));
      expect(app.autoCount.isTargetReached, isFalse);

      app.autoCount.setStopMinutes(10);
      expect(app.autoCount.targetProgress, 0.0);
      expect(app.autoCount.stopElapsedProgress, closeTo(0.5, 1e-9));
      expect(app.autoCount.stopRemainingSeconds, 300);
    });

    test('decrementAuto and decrement only touch their own record portion',
        () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final app =
          AppControllers.create(storage: storage, audio: AudioService());
      final today = DateTime.now();

      await app.practice.records.addCount(today, manual: 0, auto: 5);
      await storage.setAutoCounter(5);
      final app2 = AppControllers.create(
        storage: storage,
        audio: AudioService(),
        records: app.practice.records,
      );
      app2.practice.increment();
      app2.practice.increment();
      expect(app2.practice.records.getRecord(today).manualCount, 2);
      expect(app2.practice.records.getRecord(today).autoCount, 5);

      app2.practice.decrementAuto();
      expect(app2.practice.autoCount, 4);
      expect(storage.getAutoCounter(), 4);
      expect(app2.practice.records.getRecord(today).autoCount, 4);
      expect(app2.practice.records.getRecord(today).manualCount, 2);

      app2.practice.decrement();
      expect(app2.practice.count, 1);
      expect(app2.practice.records.getRecord(today).manualCount, 1);
      expect(app2.practice.records.getRecord(today).autoCount, 4);
      expect(app2.practice.todayPracticeCount, 5);

      // 自動計數為 0 時減一不會變成負數
      app2.practice.resetAutoCount();
      app2.practice.decrementAuto();
      expect(app2.practice.autoCount, 0);
    });

    testWidgets('Auto count stops once when goal is reached, then can continue',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final handler = _FakePositionAudioHandler();
      final app = AppControllers.create(
        storage: storage,
        audio: AudioService(handler: handler),
      );
      final song = ChantConstants.getSongById(app.playback.currentSongId);
      final markers = song.phraseMarkersMs;
      expect(markers.length, greaterThanOrEqualTo(5));

      Future<void> emit(int ms) async {
        handler.positions.add(Duration(milliseconds: ms));
        await tester.pump();
      }

      app.practice.resetAutoCount();
      app.autoCount.setTargetCount(3);
      app.autoCount.start();
      expect(app.autoCount.isCounting, isTrue);

      // 起始進度歸零，解除「等待重新開始」保護
      await emit(0);
      await emit(markers[0] + 10);
      await emit(markers[1] + 10);
      expect(app.practice.autoCount, 2);
      expect(app.autoCount.isCounting, isTrue);

      // 第 3 聲念滿目標 -> 自動停止
      await emit(markers[2] + 10);
      expect(app.practice.autoCount, 3);
      expect(app.autoCount.isTargetReached, isTrue);
      expect(app.autoCount.isCounting, isFalse);

      // 停止後的進度推播不再累加
      await emit(markers[3] + 10);
      expect(app.practice.autoCount, 3);

      // 已達標後再按開始：繼續念，不會一開始就被停止
      app.autoCount.start();
      await emit(0);
      await emit(markers[0] + 10);
      expect(app.practice.autoCount, 4);
      expect(app.autoCount.isCounting, isTrue);

      app.autoCount.stop();
      app.dispose();
    });

    testWidgets(
        'ModernTimerView shows goal ring, 減一, 重置 and single start button',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        StorageService.keyAutoCounter: 27,
      });
      final storage = await StorageService.init();
      final app =
          AppControllers.create(storage: storage, audio: AudioService());
      app.autoCount.setTargetCount(108);

      await tester.pumpWidget(
        app.provide(
          child: testApp(home: const Scaffold(body: ModernTimerView())),
        ),
      );
      await tester.pump();

      expect(find.text('目標 108'), findsOneWidget);
      expect(find.text('目標 108 · 25%'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('重置'), findsOneWidget);
      expect(find.text('開始'), findsOneWidget);

      await tester.tap(find.text('減一'));
      await tester.pump();
      expect(app.practice.autoCount, 26);

      // 清除停止條件 -> 不顯示進度環
      app.autoCount.clearStopCondition();
      await tester.pump();
      expect(find.text('持續播放'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}

/// 可手動推送播放進度的音訊處理器，用以模擬佛號節拍跨過標記點
class _FakePositionAudioHandler extends ChantAudioHandler {
  final StreamController<Duration> positions =
      StreamController<Duration>.broadcast();

  @override
  Stream<Duration> get onPositionChanged => positions.stream;
}

class _CountingAudioHandler extends ChantAudioHandler {
  int playSongCalls = 0;

  @override
  Future<void> playSong(int songId) {
    playSongCalls++;
    return super.playSong(songId);
  }
}
