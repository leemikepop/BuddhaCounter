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
import 'package:buddha_counter/ui/modern/widgets/modern_floating_player.dart';
import 'package:buddha_counter/ui/modern/views/modern_counter_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
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
      expect(storage.getThemeMode(), 'system');
      expect(storage.getTargetCount(), 108);
      expect(storage.getVibrationEnabled(), true);

      await storage.setThemeMode('dark');
      expect(storage.getThemeMode(), 'dark');

      await storage.setTargetCount(1080);
      expect(storage.getTargetCount(), 1080);

      await storage.setVibrationEnabled(false);
      expect(storage.getVibrationEnabled(), false);
    });

    test('CounterViewModel starts auto count cleanly without stale audio beat jumps', () async {
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

    test('Separated resetAutoCount and resetAutoTimer work independently', () async {
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

    testWidgets('ModernCounterView renders and updates without ListTile warnings', (tester) async {
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
  });
}



