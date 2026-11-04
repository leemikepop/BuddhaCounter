import 'package:buddha_counter/app/app_controllers.dart';
import 'package:buddha_counter/core/constants/chant_songs.dart';
import 'package:buddha_counter/core/services/audio_service.dart';
import 'package:buddha_counter/core/services/storage_service.dart';
import 'package:buddha_counter/core/utils/time_format.dart';
import 'package:buddha_counter/features/practice/session_stopwatch.dart';
import 'package:buddha_counter/l10n/l10n.dart';
import 'package:buddha_counter/ui/common/song_tag_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_app.dart';

/// 各 controller 的行為與彼此的接線 (不經過畫面)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpTestPlatformMocks();

  late StorageService storage;
  late AppControllers app;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await StorageService.init();
    app = AppControllers.create(storage: storage, audio: AudioService());
  });

  tearDown(() => app.dispose());

  group('playback hand-off to auto count', () {
    test('on the auto-count screen the play button starts counting', () {
      app.autoCount.setScreenVisible(true);
      app.playback.toggleChant(app.playback.currentSongId);
      expect(app.autoCount.isCounting, isTrue);
      expect(app.playback.isPlaying, isTrue);

      app.playback.toggleChant(app.playback.currentSongId);
      expect(app.autoCount.isCounting, isFalse);
      expect(app.playback.isPlaying, isFalse);
    });

    test('after leaving the auto-count screen the play button only plays', () {
      app.autoCount.setScreenVisible(true);
      app.autoCount.setScreenVisible(false);
      app.playback.toggleChant(app.playback.currentSongId);
      expect(app.playback.isPlaying, isTrue);
      expect(app.autoCount.isCounting, isFalse);
    });

    test('choosing another song while counting keeps counting on the new song',
        () {
      app.autoCount.start();
      app.playback.selectSong(3);
      expect(app.playback.currentSongId, 3);
      expect(storage.getLastSongId(), 3);
      expect(app.autoCount.isCounting, isTrue);
      expect(app.playback.position, Duration.zero);
    });

    test('choosing a song while not counting does not start playback', () {
      app.playback.selectSong(5);
      expect(app.playback.currentSongId, 5);
      expect(app.playback.isPlaying, isFalse);
      expect(app.autoCount.isCounting, isFalse);
    });

    test('next / previous wrap around the song list', () {
      final total = ChantConstants.allSongs.length;
      app.playback.selectSong(total - 1);
      app.playback.playNextSong();
      expect(app.playback.currentSongId, 0);
      app.playback.playPreviousSong();
      expect(app.playback.currentSongId, total - 1);
    });

    test('resetAll stops and clears both count and elapsed time', () async {
      await storage.setAutoCounter(7);
      await storage.setAutoElapsedSeconds(42);
      final restored =
          AppControllers.create(storage: storage, audio: AudioService());
      addTearDown(restored.dispose);
      restored.autoCount.start();

      restored.autoCount.resetAll();
      expect(restored.autoCount.isCounting, isFalse);
      expect(restored.practice.autoCount, 0);
      expect(restored.autoCount.elapsedSeconds, 0);
      expect(storage.getAutoElapsedSeconds(), 0);
    });
  });

  group('practice', () {
    test('auto beats are added to today and to the calendar record', () {
      app.practice.addAutoBeats(3);
      expect(app.practice.autoCount, 3);
      expect(storage.getAutoCounter(), 3);
      expect(app.practice.records.getRecord(DateTime.now()).autoCount, 3);
      expect(app.practice.todayPracticeCount, 3);
    });

    test('zero beats change nothing', () {
      var notified = 0;
      app.practice.addListener(() => notified++);
      app.practice.addAutoBeats(0);
      expect(notified, 0);
      expect(app.practice.autoCount, 0);
    });

    test('editing today in the calendar also updates the manual counter',
        () async {
      await app.practice.setPracticeCount(DateTime.now(), 50);
      expect(app.practice.count, 50);
      await app.practice.adjustPracticeCount(DateTime.now(), 8);
      expect(app.practice.count, 58);
      await app.practice.clearPracticeDate(DateTime.now());
      expect(app.practice.count, 0);
    });

    test('editing another day leaves today alone', () async {
      app.practice.increment();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await app.practice.setPracticeCount(yesterday, 300);
      expect(app.practice.count, 1);
      expect(app.practice.records.getCount(yesterday), 300);
    });
  });

  group('settings', () {
    test('keep screen on is stored under one key', () {
      app.settings.toggleKeepScreenOn();
      expect(app.settings.keepScreenOn, isTrue);
      expect(storage.getKeepScreenOn(), isTrue);
      app.settings.setKeepScreenOn(false);
      expect(storage.getKeepScreenOn(), isFalse);
    });

    test('theme mode round-trips through storage', () {
      for (final mode in ThemeMode.values) {
        app.settings.setThemeMode(mode);
        final reloaded =
            AppControllers.create(storage: storage, audio: AudioService());
        expect(reloaded.settings.themeMode, mode);
        reloaded.dispose();
      }
    });

    test('dedication index is clamped to the available verses', () async {
      await app.settings.setHuiXiangIndex(99);
      expect(app.settings.huiXiangIndex, ChantConstants.huiXiangCount - 1);
    });
  });

  group('SessionStopwatch', () {
    testWidgets('counts seconds while running and resets to zero',
        (tester) async {
      final stopwatch = SessionStopwatch()..start();
      await tester.pump(const Duration(seconds: 3));
      expect(stopwatch.elapsedSeconds, 3);

      stopwatch.toggle();
      expect(stopwatch.isRunning, isFalse);
      await tester.pump(const Duration(seconds: 5));
      expect(stopwatch.elapsedSeconds, 3);

      stopwatch.reset();
      expect(stopwatch.formatted, '00:00:00');
      stopwatch.dispose();
    });
  });

  group('helpers', () {
    test('time formatting', () {
      expect(formatHms(0), '00:00:00');
      expect(formatHms(3725), '01:02:05');
      expect(formatMinSec(const Duration(minutes: 3, seconds: 7)), '03:07');
    });

    test('song filter matches tag, title and translated tag label', () {
      final l10n = lookupAppLocalizations(kEn);
      ChantConstants.applyLocale(kEn);
      final all = ChantConstants.allSongs;

      final byTag =
          filterSongs(all, l10n: l10n, tag: ChantTag.fourCharAmitabha);
      expect(byTag, isNotEmpty);
      expect(byTag.every((s) => s.tags.contains(ChantTag.fourCharAmitabha)),
          isTrue);

      final byKeyword = filterSongs(all, l10n: l10n, keyword: 'KSITIGARBHA');
      expect(byKeyword, hasLength(1));

      expect(
          filterSongs(all, l10n: l10n, keyword: '  '), hasLength(all.length));
      expect(filterSongs(all, l10n: l10n, keyword: 'zzzz'), isEmpty);
    });
  });
}
