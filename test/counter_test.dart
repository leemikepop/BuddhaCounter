import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buddha_counter/core/constants/chant_songs.dart';
import 'package:buddha_counter/core/services/audio_service.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
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
      (call) async => 1,
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

    test('Default sound effect is woodfish', () async {
      final storage = await StorageService.init();
      expect(storage.getSoundEffect(), SoundEffectType.woodfish);
    });

    test('Default UI mode is legacy', () async {
      final storage = await StorageService.init();
      expect(storage.getUiMode(), AppUiMode.legacy);
    });
  });

  group('Chant Songs & Tempo (bb) Tests', () {
    test('Contains exactly 31 songs from legacy Count3', () {
      final songs = ChantConstants.getAllSongs();
      expect(songs.length, 31);
    });

    test('First song is amitabha.mp3 with 3850ms interval', () {
      final song = ChantConstants.getSongById(0);
      expect(song.id, 0);
      expect(song.title, '阿彌陀佛-四字四音');
      expect(song.assetPath, 'audio/amitabha.mp3');
      expect(song.beatIntervalMs, 3850);
    });

    test('Song 26 (fast 4-character) has 750ms interval and bb27.mp3', () {
      final song = ChantConstants.getSongById(26);
      expect(song.title, '淨空法師念佛 快速四字版');
      expect(song.assetPath, 'audio/bb27.mp3');
      expect(song.beatIntervalMs, 750);
    });

    test('Song 2 (slow 6-tone) has 13510ms interval and bb3.mp3', () {
      final song = ChantConstants.getSongById(2);
      expect(song.title, '靈巖梵唄-南無阿彌陀佛聖號-六度彌陀');
      expect(song.assetPath, 'audio/bb3.mp3');
      expect(song.beatIntervalMs, 13510);
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

    test('Component 1 (toggleChant) toggles auto-count when in auto-count mode',
        () async {
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
    });

    test(
        'Component 1 (toggleChant) only plays background music when NOT in auto-count mode',
        () async {
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
        'ModernPracticeView renders Buddha image and identical verses with Legacy',
        (tester) async {
      final storage = await StorageService.init();
      final audio = AudioService();
      final vm = CounterViewModel(storage: storage, audio: audio);

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

      // 驗證阿彌陀佛聖像、大回向西方文標題與偈頌文句
      expect(find.byType(Image), findsOneWidget);
      expect(find.text(ChantConstants.huiXiangTitle), findsOneWidget);
      expect(find.text(ChantConstants.huiXiangVerses.first), findsOneWidget);
      expect(find.text('南無阿彌陀佛'), findsOneWidget);
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
      expect(find.text('設定今日念佛目標'), findsOneWidget);
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
      expect(find.text('888 聲 (自訂)'), findsOneWidget);
    });

    testWidgets('ModernGuideDialog renders slides and navigates through pages',
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

      // 驗證第 1 頁內容
      expect(find.text('現代禪意 · 沉浸專注'), findsOneWidget);
      expect(find.text('下一步'), findsOneWidget);

      // 點擊下一步切換至第 2 頁
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
      expect(find.text('三大專屬修持分頁'), findsOneWidget);

      // 點擊關閉/完成
      final closeButton = find.byIcon(Icons.close_rounded);
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // 對話框已關閉
      expect(find.text('現代禪意 · 沉浸專注'), findsNothing);
    });
  });
}
