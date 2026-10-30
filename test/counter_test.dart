import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buddha_counter/core/constants/chant_songs.dart';
import 'package:buddha_counter/core/services/audio_service.dart';
import 'package:buddha_counter/core/services/chant_audio_handler.dart';
import 'package:buddha_counter/core/services/storage_service.dart';
import 'package:buddha_counter/features/counter/counter_view_model.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:buddha_counter/ui/modern/widgets/modern_floating_player.dart';
import 'package:buddha_counter/ui/modern/views/modern_counter_view.dart';
import 'package:buddha_counter/ui/modern/views/modern_timer_view.dart';
import 'package:buddha_counter/ui/modern/screens/modern_counter_screen.dart';
import 'package:buddha_counter/ui/modern/views/modern_practice_view.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:buddha_counter/ui/legacy/screens/legacy_counter_screen.dart';
import 'package:buddha_counter/ui/legacy/screens/legacy_settings_screen.dart';
import 'package:buddha_counter/ui/legacy/screens/legacy_about_screen.dart';
import 'package:buddha_counter/ui/common/app_toast.dart';
import 'package:buddha_counter/ui/modern/widgets/modern_guide_dialog.dart';
import 'package:buddha_counter/ui/modern/widgets/song_list_tile.dart';
import 'package:buddha_counter/core/services/practice_record_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AudioPlayer.preparationTimeout = const Duration(milliseconds: 10);
    AudioPlayer.seekingTimeout = const Duration(milliseconds: 10);
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: '念佛計數器',
      packageName: 'com.yichung.lee.buddha_counter',
      version: '1.48.0',
      buildNumber: '148',
      buildSignature: '',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (call) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        final playerId = call.arguments?['playerId'];
        if (playerId != null) {
          final eventChannel = 'xyz.luan/audioplayers/events/$playerId';
          if (call.method == 'seek') {
            final ByteData message =
                const StandardMethodCodec().encodeSuccessEnvelope({
              'event': 'audio.onSeekComplete',
            });
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
                .handlePlatformMessage(eventChannel, message, (data) {});
          } else if (call.method == 'setSourceUrl' ||
              call.method == 'setSourceBytes') {
            final ByteData message =
                const StandardMethodCodec().encodeSuccessEnvelope({
              'event': 'audio.onPrepared',
              'value': true,
            });
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
                .handlePlatformMessage(eventChannel, message, (data) {});
          }
        }
        return 1;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.audio_service.client.methods'),
      (call) async => {},
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.audio_service.handler.methods'),
      (call) async => {},
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.path,
    );
  });

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

    test('All 31 songs have calibrated beatIntervalMs, ascending markers, and tags', () {
      for (final song in ChantConstants.defaultSongs) {
        expect(song.phraseMarkersMs, isNotEmpty);
        expect(song.tags, isNotEmpty);
        for (var i = 1; i < song.phraseMarkersMs.length; i++) {
          expect(song.phraseMarkersMs[i], greaterThan(song.phraseMarkersMs[i - 1]));
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
      expect(ChantConstants.availableTags, contains(ChantTags.fourCharAmitabha));
      expect(ChantConstants.countSongsByTag(ChantTags.fourCharAmitabha), 12);
    });

    test('loadMetadataFromAssets reads OGG Vorbis title, artist, album with defaults', () async {
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
      expect(() => AudioService(), returnsNormally);
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
        'CounterViewModel starts auto count cleanly without stale audio beat jumps',
        () async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final vm = CounterViewModel(storage: storage, audio: audio);

      expect(vm.isAutoCounting, false);
      vm.resetAutoCount();
      expect(vm.autoCount, 0);

      // 啟動自動計數
      vm.startAutoCount();
      expect(vm.isAutoCounting, true);
      // 確保一開始不會立刻累加舊在途節拍
      expect(vm.autoCount, 0);

      vm.stopAutoCount();
      expect(vm.isAutoCounting, false);
    });

    test('Phrase markers and scrubbing seek prevent count miscalculation', () async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final vm = CounterViewModel(storage: storage, audio: audio);

      vm.resetAutoCount();
      expect(vm.autoCount, 0);

      // 模擬手動拖動進度條
      vm.beginScrubbing();
      expect(vm.isScrubbing, true);

      // 放開進度條跳至 25 秒
      vm.endScrubbing(const Duration(seconds: 25));
      expect(vm.isScrubbing, false);
      expect(vm.audioPosition, const Duration(seconds: 25));

      // 驗證跳轉未造成次數暴增或亂加
      expect(vm.autoCount, 0);
    });

    test('Separated resetAutoCount and resetAutoTimer work independently',
        () async {
      final storage = await StorageService.init();
      final audio = AudioService();

      // 模擬有計數與計時數值
      await storage.setAutoCounter(50);
      await storage.setAutoElapsedSeconds(120);
      final vm2 = CounterViewModel(storage: storage, audio: audio);

      expect(vm2.autoCount, 50);
      expect(vm2.autoElapsedSeconds, 120);

      // 僅重置計時 -> 計數應保持 50，計時歸 0
      vm2.resetAutoTimer();
      expect(vm2.autoCount, 50);
      expect(vm2.autoElapsedSeconds, 0);

      // 僅重置計數 -> 計數歸 0，計時不受影響
      await storage.setAutoElapsedSeconds(180);
      final vm3 = CounterViewModel(storage: storage, audio: audio);
      expect(vm3.autoCount, 50);
      expect(vm3.autoElapsedSeconds, 180);

      vm3.resetAutoCount();
      expect(vm3.autoCount, 0);
      expect(vm3.autoElapsedSeconds, 180);
    });

    testWidgets('MarqueeText renders text cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
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
      final vm = CounterViewModel(storage: storage, audio: audio);

      await tester.pumpWidget(
        ChangeNotifierProvider<CounterViewModel>.value(
          value: vm,
          child: const MaterialApp(
            home: Scaffold(
              body: ModernCounterView(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Trigger rebuilds (increment count)
      vm.resetCount();
      vm.increment();
      await tester.pump();
      expect(vm.count, 1);

      // Verify toggle vibration and fullscreen
      vm.setVibrationEnabled(false);
      vm.setFullscreenTap(true);
      await tester.pump();
    });

    testWidgets(
        'ModernTimerView renders clean Zen disc without spinning progress ring',
        (tester) async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final vm = CounterViewModel(storage: storage, audio: audio);

      await tester.pumpWidget(
        ChangeNotifierProvider<CounterViewModel>.value(
          value: vm,
          child: const MaterialApp(
            home: Scaffold(
              body: ModernTimerView(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify clean Zen disc contains auto count number
      expect(find.text(vm.autoCount.toString()), findsOneWidget);
      expect(find.text('聲 · 遍'), findsOneWidget);
      // Verify CircularProgressIndicator has been removed
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    test('AudioService maintains loop mode and exposes onPlayerComplete stream',
        () {
      final audio = AudioService();
      expect(audio.releaseMode, ReleaseMode.loop);
      expect(audio.onPlayerComplete, isNotNull);
    });

    testWidgets('AppToast renders message correctly and dismisses',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
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
      final vm = CounterViewModel(storage: storage, audio: audio);

      // 現代模式預設第 0 頁 (手動計數)
      vm.setUiMode(AppUiMode.modern);
      vm.setActiveTabIndex(0);
      expect(vm.isInAutoCountMode, isFalse);

      // 切換至第 1 頁 (自動計數)
      vm.setActiveTabIndex(1);
      expect(vm.isInAutoCountMode, isTrue);

      // 切換至第 2 頁 (迴向)
      vm.setActiveTabIndex(2);
      expect(vm.isInAutoCountMode, isFalse);

      // 切換至經典模式
      vm.setUiMode(AppUiMode.legacy);
      expect(vm.isInAutoCountMode, isFalse);
      vm.setIsInLegacyAutoCountScreen(true);
      expect(vm.isInAutoCountMode, isTrue);
      vm.setIsInLegacyAutoCountScreen(false);
      expect(vm.isInAutoCountMode, isFalse);
    });

    testWidgets(
        'Component 1 (toggleChant) toggles auto-count when in auto-count mode',
        (tester) async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final vm = CounterViewModel(storage: storage, audio: audio);

      vm.setUiMode(AppUiMode.modern);
      vm.setActiveTabIndex(1); // 自動計數頁
      expect(vm.isAutoCounting, isFalse);
      expect(vm.isChantPlaying, isFalse);

      // 點擊元件 1 的播放
      vm.toggleChant(vm.currentSongId);
      expect(vm.isAutoCounting, isTrue);
      expect(vm.isChantPlaying, isTrue);

      // 點擊元件 1 的暫停：必須連動暫停自動計數
      vm.toggleChant(vm.currentSongId);
      expect(vm.isAutoCounting, isFalse);
      expect(vm.isChantPlaying, isFalse);

      // 點擊元件 2/3 (toggleAutoCount) 的開始：連動啟動
      vm.toggleAutoCount();
      expect(vm.isAutoCounting, isTrue);
      expect(vm.isChantPlaying, isTrue);

      // 再次點擊元件 1 的暫停：同步暫停
      vm.toggleChant(vm.currentSongId);
      expect(vm.isAutoCounting, isFalse);
      expect(vm.isChantPlaying, isFalse);
      vm.dispose();
    });

    testWidgets(
        'Component 1 (toggleChant) only plays background music when NOT in auto-count mode',
        (tester) async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final vm = CounterViewModel(storage: storage, audio: audio);

      vm.setUiMode(AppUiMode.modern);
      vm.setActiveTabIndex(0); // 手動計數頁 (非自動計數)
      expect(vm.isAutoCounting, isFalse);
      expect(vm.isChantPlaying, isFalse);

      // 點擊元件 1 的播放
      vm.toggleChant(vm.currentSongId);
      // 音樂有在播放，但自動計數絕不會啟動
      expect(vm.isChantPlaying, isTrue);
      expect(vm.isAutoCounting, isFalse);

      // 點擊元件 1 的暫停
      vm.toggleChant(vm.currentSongId);
      expect(vm.isChantPlaying, isFalse);
      expect(vm.isAutoCounting, isFalse);
      vm.dispose();
    });

    testWidgets(
        'UI Sync: Component 1, Component 2, and Component 3 stay 100% in sync',
        (tester) async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final vm = CounterViewModel(storage: storage, audio: audio);

      vm.setUiMode(AppUiMode.modern);
      vm.setActiveTabIndex(1); // 位於自動計數頁

      await tester.pumpWidget(
        ChangeNotifierProvider<CounterViewModel>.value(
          value: vm,
          child: const MaterialApp(
            home: Scaffold(
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
      expect(vm.isAutoCounting, isTrue);
      expect(vm.isChantPlaying, isTrue);

      // 2. 透過【元件 2 (中間大按鈕)】點擊暫停
      await tester.tap(find.text('暫停'));
      await tester.pump();

      // 驗證 1、2、3 全部同步回到「開始」/「播放」狀態
      expect(find.text('開始'), findsOneWidget); // 元件 2
      expect(find.byTooltip('開始'), findsOneWidget); // 元件 3
      expect(find.byTooltip('播放'), findsOneWidget); // 元件 1
      expect(vm.isAutoCounting, isFalse);
      expect(vm.isChantPlaying, isFalse);

      // 3. 透過【元件 3 (碼表按鈕)】點擊開始
      await tester.tap(find.byTooltip('開始'));
      await tester.pump();

      // 驗證 1、2、3 再次全部同步轉為「暫停」狀態
      expect(find.text('暫停'), findsOneWidget);
      expect(find.byTooltip('暫停'), findsNWidgets(2));
      expect(vm.isAutoCounting, isTrue);
      expect(vm.isChantPlaying, isTrue);

      // 4. 再次透過【元件 1 (播放器)】點擊暫停
      await tester.tap(find.byTooltip('暫停').last);
      await tester.pump();

      // 驗證 1、2、3 再次全部同步回到「開始」/「播放」狀態
      expect(find.text('開始'), findsOneWidget);
      expect(find.byTooltip('開始'), findsOneWidget);
      expect(find.byTooltip('播放'), findsOneWidget);
      expect(vm.isAutoCounting, isFalse);
      expect(vm.isChantPlaying, isFalse);
    });
  });

  group('Custom Timer & Orientation Lock Tests', () {
    testWidgets('Custom stop minutes picker allows setting arbitrary minutes',
        (tester) async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final vm = CounterViewModel(storage: storage, audio: audio);

      await tester.pumpWidget(
        ChangeNotifierProvider<CounterViewModel>.value(
          value: vm,
          child: const MaterialApp(
            home: Scaffold(
              body: ModernTimerView(),
            ),
          ),
        ),
      );
      await tester.pump();

      // 點擊定時停止設定按鈕打開 BottomSheet
      await tester.tap(find.textContaining('定時停止'));
      await tester.pumpAndSettle();

      // 驗證標題已更新為「設定定時停止時長」
      expect(find.text('設定定時停止時長'), findsOneWidget);

      // 輸入自訂分鐘數 25
      await tester.enterText(find.byType(TextField), '25');
      await tester.pump();

      // 點擊「設定」按鈕
      await tester.tap(find.widgetWithText(FilledButton, '設定'));
      await tester.pumpAndSettle();

      // 驗證 ViewModel 與外層按鈕顯示已更新為 25 分鐘
      expect(vm.autoStopMinutes, 25);
      expect(find.text('定時停止：25 分鐘'), findsOneWidget);
    });

    test('Orientation lock toggles and updates StorageService', () async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final vm = CounterViewModel(storage: storage, audio: audio);

      expect(vm.isOrientationLocked, isFalse);
      expect(storage.getOrientationLocked(), isFalse);

      vm.toggleOrientationLock();
      expect(vm.isOrientationLocked, isTrue);
      expect(storage.getOrientationLocked(), isTrue);

      vm.toggleOrientationLock();
      expect(vm.isOrientationLocked, isFalse);
      expect(storage.getOrientationLocked(), isFalse);
    });

    testWidgets('ModernCounterScreen AppBar contains orientation lock button',
        (tester) async {
      final storage = await StorageService.init();
      await storage.setOrientationLocked(false);
      final audio = AudioService();
      final vm = CounterViewModel(storage: storage, audio: audio);

      await tester.pumpWidget(
        ChangeNotifierProvider<CounterViewModel>.value(
          value: vm,
          child: const MaterialApp(
            home: ModernCounterScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byTooltip('鎖定螢幕方向'), findsOneWidget);

      // 點擊方向鎖定按鈕
      await tester.tap(find.byTooltip('鎖定螢幕方向'));
      await tester.pumpAndSettle();
      expect(vm.isOrientationLocked, isTrue);
      expect(find.byTooltip('解除方向鎖定'), findsOneWidget);
    });

    testWidgets('LegacyCounterScreen AppBar contains orientation lock button',
        (tester) async {
      final storage = await StorageService.init();
      await storage.setOrientationLocked(false);
      final audio = AudioService();
      final vm = CounterViewModel(storage: storage, audio: audio);

      await tester.pumpWidget(
        ChangeNotifierProvider<CounterViewModel>.value(
          value: vm,
          child: const MaterialApp(
            home: LegacyCounterScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byTooltip('鎖定螢幕方向'), findsOneWidget);

      await tester.tap(find.byTooltip('鎖定螢幕方向'));
      await tester.pumpAndSettle();
      expect(vm.isOrientationLocked, isTrue);
      expect(find.byTooltip('解除方向鎖定'), findsOneWidget);
    });

    testWidgets(
        'AppBar contains screen awake button that toggles keep screen on',
        (tester) async {
      final storage = await StorageService.init();
      await storage.setKeepScreenOnHome(false);
      final audio = AudioService();
      final vm = CounterViewModel(storage: storage, audio: audio);

      await tester.pumpWidget(
        ChangeNotifierProvider<CounterViewModel>.value(
          value: vm,
          child: const MaterialApp(
            home: ModernCounterScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byTooltip('螢幕常亮'), findsOneWidget);

      // 點擊切換螢幕常亮
      await tester.tap(find.byTooltip('螢幕常亮'));
      await tester.pumpAndSettle();
      expect(vm.isCurrentScreenAwake, isTrue);
      expect(find.byTooltip('關閉螢幕常亮'), findsOneWidget);
    });

    testWidgets(
        'ModernPracticeView renders Buddha image and swipeable HuiXiang verses',
        (tester) async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final vm = CounterViewModel(storage: storage, audio: audio);
      await vm.setHuiXiangIndex(0);

      await tester.pumpWidget(
        ChangeNotifierProvider<CounterViewModel>.value(
          value: vm,
          child: const MaterialApp(
            home: Scaffold(
              body: ModernPracticeView(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      // 驗證阿彌陀佛聖像、大回向西方文標題與偈頌文句
      expect(find.byType(Image), findsOneWidget);
      expect(find.text(ChantConstants.huiXiangTitle), findsOneWidget);
      expect(find.text(ChantConstants.huiXiangVerses.first), findsOneWidget);
      expect(find.text('南無阿彌陀佛'), findsOneWidget);

      // 向左滑動切換至第二則迴向文（回向偈）
      await tester.fling(
        find.text(ChantConstants.huiXiangTitle),
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(vm.huiXiangIndex, 1);
      expect(find.text(ChantConstants.huiXiangTitle2), findsOneWidget);
      expect(find.text(ChantConstants.huiXiangVerses2.first), findsOneWidget);

      // 向右滑動切回第一則迴向文（大回向西方文）
      await tester.fling(
        find.text(ChantConstants.huiXiangTitle2),
        const Offset(300, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(vm.huiXiangIndex, 0);
      expect(find.text(ChantConstants.huiXiangTitle), findsOneWidget);
    });

    test('autoStopProgress calculates remaining fraction correctly', () async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final vm = CounterViewModel(storage: storage, audio: audio);
      vm.resetAutoTimer();

      // 初始未設定時
      vm.setAutoStopMinutes(0);
      expect(vm.autoStopProgress, 0.0);

      // 設定 10 分鐘
      vm.setAutoStopMinutes(10);
      expect(vm.autoStopProgress, 1.0); // 尚未計時，進度 100%
    });

    testWidgets(
        'LegacyCounterScreen central button displays count and increments when tapped',
        (tester) async {
      final storage = await StorageService.init();
      await storage.setOrientationLocked(false);
      final audio = AudioService();
      final vm = CounterViewModel(storage: storage, audio: audio);
      vm.resetCount();

      await tester.pumpWidget(
        ChangeNotifierProvider<CounterViewModel>.value(
          value: vm,
          child: const MaterialApp(
            home: LegacyCounterScreen(),
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
      expect(vm.count, 1);
      expect(find.widgetWithText(ElevatedButton, '1'), findsOneWidget);
    });

    testWidgets('LegacySettingsScreen contains unified screen awake switch',
        (tester) async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final vm = CounterViewModel(storage: storage, audio: audio);
      vm.setScreenAwake(false);

      await tester.pumpWidget(
        ChangeNotifierProvider<CounterViewModel>.value(
          value: vm,
          child: const MaterialApp(
            home: LegacySettingsScreen(),
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

      expect(vm.isCurrentScreenAwake, isTrue);
    });

    testWidgets(
        'LegacyAboutScreen displays dynamic project version from PackageInfo',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LegacyAboutScreen(),
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
      final vm = CounterViewModel(storage: storage, audio: audio);

      expect(storage.getSeenModernGuide(), isFalse);
      expect(vm.hasSeenModernGuide, isFalse);

      await vm.markModernGuideSeen();
      expect(storage.getSeenModernGuide(), isTrue);
      expect(vm.hasSeenModernGuide, isTrue);
    });

    testWidgets('ModernCounterView allows setting custom target count',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final audio = AudioService();
      final vm = CounterViewModel(storage: storage, audio: audio);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: const MaterialApp(
            home: Scaffold(
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
      expect(find.text('設定今日目標'), findsOneWidget);
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
      expect(vm.targetCount, 888);
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
      final vm = CounterViewModel(storage: storage, audio: audio);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp(
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
      expect(vm.hasSeenModernGuide, isTrue);

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
      expect(() => audio.dispose(), returnsNormally);
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
      final vm = CounterViewModel(storage: storage, audio: audio);

      await tester.pumpWidget(
        ChangeNotifierProvider<CounterViewModel>.value(
          value: vm,
          child: const MaterialApp(
            home: ModernCounterScreen(),
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
          '${ChantTags.pilgrimage} (${ChantConstants.countSongsByTag(ChantTags.pilgrimage)})';
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
      final vm = CounterViewModel(storage: storage, audio: audio);

      // 1. 現代模式【自動計數】分頁：點擊佛曲（無論尚未開始或正在計數中）皆只呼叫一次 playSong，絕不陷入無限微任務迴圈
      vm.setUiMode(AppUiMode.modern);
      vm.setActiveTabIndex(1);
      vm.selectAndPlaySong(11); // #12 南無阿彌陀佛-思鄉佛號
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(countingHandler.playSongCalls, 1);
      expect(vm.currentSongId, 11);
      expect(vm.isAutoCounting, isTrue);
      expect(vm.isChantPlaying, isTrue);

      // 自動計數進行中再次點擊另一首佛曲（#28 南無地藏王菩薩）
      vm.selectAndPlaySong(27);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(countingHandler.playSongCalls, 2);
      expect(vm.currentSongId, 27);
      expect(vm.isAutoCounting, isTrue);
      expect(vm.isChantPlaying, isTrue);

      // 透過 toggleChant 點擊另一首不同佛曲（#05）應直接切換播放而非誤暫停
      vm.toggleChant(4);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(countingHandler.playSongCalls, 3);
      expect(vm.currentSongId, 4);
      expect(vm.isAutoCounting, isTrue);
      expect(vm.isChantPlaying, isTrue);

      // 停止後切回【手動計數】分頁並實際在展開的佛曲清單 UI 中點擊曲目
      vm.stopAutoCount();
      await tester.pump();
      vm.setActiveTabIndex(0);

      await tester.pumpWidget(
        ChangeNotifierProvider<CounterViewModel>.value(
          value: vm,
          child: const MaterialApp(
            home: ModernCounterScreen(),
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
      expect(vm.currentSongId, 0);
      expect(vm.isChantPlaying, isTrue);
      expect(vm.isAutoCounting, isFalse);

      vm.stopChant();
      vm.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets(
        'Directly selecting song from stopped state properly starts playback and populates duration/position streams',
        (tester) async {
      final storage = await StorageService.init();
      final handler = _CountingAudioHandler();
      final audio = AudioService(handler: handler);
      final vm = CounterViewModel(storage: storage, audio: audio);

      vm.setUiMode(AppUiMode.modern);
      vm.setActiveTabIndex(0);
      expect(vm.isChantPlaying, isFalse);

      vm.selectAndPlaySong(3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(vm.isChantPlaying, isTrue);
      expect(vm.currentSongId, 3);
      expect(handler.playSongCalls, 1);

      vm.stopChant();
      vm.dispose();
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
        'CounterViewModel increments and manual edits synchronize with practice records',
        () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final audio = AudioService();
      final vm = CounterViewModel(storage: storage, audio: audio);

      final today = DateTime.now();
      expect(vm.todayPracticeCount, 0);

      vm.increment();
      expect(vm.count, 1);
      expect(vm.todayPracticeCount, 1);

      vm.increment();
      expect(vm.count, 2);
      expect(vm.todayPracticeCount, 2);

      vm.decrement();
      expect(vm.count, 1);
      expect(vm.todayPracticeCount, 1);

      // 透過 ViewModel 自由調整功課
      await vm.adjustPracticeCount(today, 107);
      expect(vm.count, 108);
      expect(vm.todayPracticeCount, 108);

      // 直接修改數值
      await vm.setPracticeCount(today, 1000);
      expect(vm.count, 1000);
      expect(vm.todayPracticeCount, 1000);

      // 每日提醒設定
      await vm.updateReminderSettings(enabled: true, hour: 21, minute: 30);
      expect(vm.isReminderEnabled, isTrue);
      expect(vm.reminderHour, 21);
      expect(vm.reminderMinute, 30);
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
      final vm = CounterViewModel(storage: storage, audio: audio);
      vm.markModernGuideSeen(); // 防止導覽對話框遮擋

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: const MaterialApp(
            home: ModernCounterScreen(),
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
      expect(find.text('快速增減修訂：'), findsOneWidget);

      // 點擊 +108 快捷修訂按鈕
      final add108Chip = find.widgetWithText(ActionChip, '+108');
      expect(add108Chip, findsOneWidget);
      await tester.tap(add108Chip);
      await tester.pumpAndSettle();

      expect(vm.todayPracticeCount, 108);
      expect(find.text('108'), findsWidgets);

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

      expect(vm.todayPracticeCount, 500);
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
    });
  });
}

class _CountingAudioHandler extends ChantAudioHandler {
  int playSongCalls = 0;

  @override
  Future<void> playSong(int songId) {
    playSongCalls++;
    return super.playSong(songId);
  }
}
