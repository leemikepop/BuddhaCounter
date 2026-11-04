import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buddha_counter/core/services/audio_service.dart';
import 'package:buddha_counter/core/services/notification_service.dart';
import 'package:buddha_counter/core/services/storage_service.dart';
import 'package:buddha_counter/app/app_controllers.dart';
import 'package:buddha_counter/l10n/l10n.dart';
import 'package:buddha_counter/ui/legacy/screens/legacy_settings_screen.dart';
import 'package:buddha_counter/ui/modern/screens/modern_counter_screen.dart';
import 'package:buddha_counter/ui/modern/views/modern_counter_view.dart';
import 'package:buddha_counter/ui/modern/views/modern_timer_view.dart';
import 'package:buddha_counter/ui/modern/views/modern_calendar_view.dart';
import 'package:buddha_counter/l10n/l10n_dates.dart';
import 'package:buddha_counter/l10n/chant_tag_labels.dart';
import 'package:buddha_counter/core/constants/chant_songs.dart';
import 'package:buddha_counter/core/content/chant_content.dart';
import 'package:buddha_counter/ui/modern/widgets/player_sheet/player_sheet.dart';
import 'package:buddha_counter/ui/modern/widgets/song_list_tile.dart';
import 'package:buddha_counter/ui/modern/views/modern_practice_view.dart';
import 'package:buddha_counter/ui/modern/widgets/modern_guide_dialog.dart';
import 'package:buddha_counter/ui/legacy/screens/legacy_counter_screen.dart';
import 'package:buddha_counter/ui/legacy/screens/legacy_about_screen.dart';
import 'package:buddha_counter/l10n/sound_effect_labels.dart';
import 'package:buddha_counter/core/services/chant_audio_handler.dart';
import 'package:buddha_counter/core/services/widget_service.dart';

import 'helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpTestPlatformMocks();

  group('resolveAppLocale', () {
    Locale r(List<Locale> d, [AppLanguage p = AppLanguage.system]) =>
        resolveAppLocale(d, p);

    test('zh-TW/HK/MO and Hant resolve Traditional', () {
      expect(r([const Locale('zh', 'TW')]), kZhHant);
      expect(r([const Locale('zh', 'HK')]), kZhHant);
      expect(r([const Locale('zh', 'MO')]), kZhHant);
      expect(
        r([
          const Locale.fromSubtags(
              languageCode: 'zh', scriptCode: 'Hant', countryCode: 'SG'),
        ]),
        kZhHant,
      );
    });

    test('zh-CN/SG/MY, Hans and bare zh resolve Simplified', () {
      for (final l in [
        const Locale('zh', 'CN'),
        const Locale('zh', 'SG'),
        const Locale('zh', 'MY'),
        const Locale('zh'),
        const Locale.fromSubtags(
            languageCode: 'zh', scriptCode: 'Hans', countryCode: 'HK'),
      ]) {
        expect(r([l]), kZhHans, reason: '$l');
      }
    });

    test('first matching device locale wins; unknown falls back to en', () {
      expect(r([const Locale('ms', 'MY'), const Locale('zh', 'HK')]), kZhHant);
      expect(r([const Locale('en', 'US'), const Locale('zh', 'TW')]), kEn);
      expect(r([const Locale('ja', 'JP')]), kEn);
      expect(r([]), kEn);
    });

    test('explicit preference overrides device', () {
      expect(r([const Locale('en', 'MY')], AppLanguage.zhHans), kZhHans);
      expect(r([const Locale('zh', 'CN')], AppLanguage.zhHant), kZhHant);
      expect(r([const Locale('zh', 'TW')], AppLanguage.en), kEn);
    });

    test('AppLanguage storage round trip; unknown value means system', () {
      for (final v in AppLanguage.values) {
        expect(AppLanguage.fromStorage(v.storageValue), v);
      }
      expect(AppLanguage.zhHant.storageValue, 'zh_Hant');
      expect(AppLanguage.fromStorage(null), AppLanguage.system);
      expect(AppLanguage.fromStorage('fr'), AppLanguage.system);
    });
  });

  group('language preference persistence', () {
    test('manual choice survives restart and system mode follows device',
        () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      const device = [Locale('en', 'MY')];
      final app = AppControllers.create(
        storage: storage,
        audio: AudioService(),
        deviceLocales: device,
      );
      expect(app.locale.appLanguage, AppLanguage.system);
      expect(app.locale.locale, kEn);

      app.locale.setAppLanguage(AppLanguage.zhHans);
      expect(app.locale.locale, kZhHans);

      final app2 = AppControllers.create(
        storage: storage,
        audio: AudioService(),
        deviceLocales: device,
      );
      expect(app2.locale.appLanguage, AppLanguage.zhHans);
      expect(app2.locale.locale, kZhHans);
      expect(storage.getAppLanguage(), AppLanguage.zhHans);

      app2.locale.setAppLanguage(AppLanguage.system);
      app2.locale.updateDeviceLocales(const [Locale('zh', 'HK')]);
      expect(app2.locale.locale, kZhHant);
    });
  });

  group('modern shell and manual counter', () {
    Future<AppControllers> appFor(Locale device) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      await storage.setSeenModernGuide(true);
      return AppControllers.create(
        storage: storage,
        audio: AudioService(),
        deviceLocales: [device],
      );
    }

    testWidgets('manual counter renders in en and zh_Hans', (tester) async {
      final app = await appFor(const Locale('en'));
      await tester.pumpWidget(
          liveLocaleApp(app, const Scaffold(body: ModernCounterView())));
      await tester.pump();
      expect(find.text('Goal 108'), findsOneWidget);
      expect(find.text('Goal 108 · 0%'), findsOneWidget);

      app.locale.setAppLanguage(AppLanguage.zhHans);
      await tester.pumpAndSettle();
      expect(find.text('目标 108'), findsOneWidget);
      expect(find.text('声 · 拜'), findsOneWidget);
    });

    testWidgets('bottom tabs are localized in English', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final app = await appFor(const Locale('en'));
      app.settings.setUiMode(AppUiMode.modern);
      await tester.pumpWidget(liveLocaleApp(app, const ModernCounterScreen()));
      await tester.pumpAndSettle();
      for (final label in ['Manual', 'Auto', 'Dedication', 'Calendar']) {
        expect(find.text(label), findsWidgets, reason: label);
      }
      await disposeAndSettleTimers(tester);
    });
  });

  group('auto count view', () {
    testWidgets('english labels for goal, timed stop and continuous',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        StorageService.keyAutoCounter: 27,
      });
      final storage = await StorageService.init();
      final app = AppControllers.create(
        storage: storage,
        audio: AudioService(),
        deviceLocales: const [Locale('en', 'US')],
      );
      app.autoCount.setTargetCount(108);
      await tester.pumpWidget(
          liveLocaleApp(app, const Scaffold(body: ModernTimerView())));
      await tester.pump();

      expect(find.text('Goal 108'), findsOneWidget);
      expect(find.text('Goal 108 · 25%'), findsOneWidget);
      expect(find.text('−1'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);

      app.autoCount.setStopMinutes(30);
      await tester.pump();
      expect(find.text('30 min'), findsOneWidget);
      expect(find.text('Timer 30 min · 30 min left'), findsOneWidget);

      app.autoCount.clearStopCondition();
      await tester.pump();
      expect(find.text('Continuous'), findsOneWidget);
    });
  });

  group('practice calendar', () {
    testWidgets('english month title, weekdays and daily goal row',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final app = AppControllers.create(
        storage: storage,
        audio: AudioService(),
        deviceLocales: const [Locale('en')],
      );
      await tester.pumpWidget(
          liveLocaleApp(app, const Scaffold(body: ModernCalendarView())));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      expect(find.text('${englishMonthName(now.month)} ${now.year}'),
          findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Today'), findsWidgets);
      expect(find.text('Daily goal'), findsOneWidget);
      expect(find.text('Goal 108 (0%)'), findsOneWidget);
    });

    test('english month helpers', () {
      expect(englishMonthName(11), 'November');
      expect(englishMonthShort(1), 'Jan');
    });
  });

  group('chant content', () {
    tearDown(() => ChantConstants.applyLocale(kZhHant));

    test('zh_Hans and en catalogs cover all 31 songs and dedication verses',
        () {
      final ids = {for (var i = 0; i <= 30; i++) i};
      final zhHant = chantContentFor(kZhHant);
      for (final loc in [kZhHans, kEn]) {
        final c = chantContentFor(loc);
        expect(c.songTitles.keys.toSet(), ids, reason: '$loc');
        expect(c.huiXiangItems.length, ChantConstants.huiXiangCount);
        for (var i = 0; i < c.huiXiangItems.length; i++) {
          expect(c.huiXiangItems[i].verses.length,
              zhHant.huiXiangItems[i].verses.length);
        }
        for (final s in ChantConstants.getAllSongs()) {
          expect(c.artistNames.containsKey(s.artist), isTrue,
              reason: '$loc missing artist ${s.artist}');
        }
      }
    });

    test('applyLocale localizes titles and keeps zh_Hant unchanged', () async {
      await ChantConstants.loadMetadataFromAssets();
      ChantConstants.applyLocale(kZhHans);
      expect(ChantConstants.getSongById(0).title.startsWith('阿弥陀佛'), isTrue);
      expect(ChantConstants.getSongById(0).artist, '悟道法师');

      ChantConstants.applyLocale(kEn);
      expect(ChantConstants.getSongById(11).title, contains('Namo Amitabha'));
      expect(ChantConstants.getSongById(1).artist,
          chantContentFor(kEn).defaultArtist);
      expect(ChantConstants.getSongById(1).album, 'Buddha Counter');
      expect(ChantConstants.huiXiangItems.first.title,
          chantContentFor(kEn).huiXiangItems.first.title);

      ChantConstants.applyLocale(kZhHant);
      expect(ChantConstants.getSongById(0).title, '阿彌陀佛-四字四音-華藏淨宗-悟道法師');
      expect(ChantConstants.getSongById(0).artist, '悟道法師');
      expect(ChantConstants.huiXiangItems.first.title, '大回向西方文');
    });

    test('tag counts are identical in every language', () {
      for (final loc in [kZhHant, kZhHans, kEn]) {
        ChantConstants.applyLocale(loc);
        expect(ChantConstants.countSongsByTag(ChantTag.fourCharAmitabha), 12);
        expect(ChantConstants.availableTags.first, ChantTag.fourCharAmitabha);
      }
    });

    test('every tag has a label in every language', () {
      for (final loc in [kZhHant, kZhHans, kEn]) {
        final l10n = lookupAppLocalizations(loc);
        for (final t in ChantTag.values) {
          expect(chantTagLabel(l10n, t), isNotEmpty);
        }
      }
      expect(
          chantTagLabel(
              lookupAppLocalizations(kZhHant), ChantTag.fourCharAmitabha),
          '四字彌陀');
    });

    test('view model applies content locale on language change', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final app = AppControllers.create(
        storage: storage,
        audio: AudioService(),
        deviceLocales: const [Locale('zh', 'TW')],
      );
      expect(ChantConstants.huiXiangItems.first.title, '大回向西方文');
      app.locale.setAppLanguage(AppLanguage.zhHans);
      expect(
          ChantConstants.huiXiangItems.first.verses.first, startsWith('愿我临终'));
    });
  });

  group('player and song lists', () {
    Future<AppControllers> zhVm(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      return AppControllers.create(
        storage: storage,
        audio: AudioService(),
        deviceLocales: const [Locale('zh', 'TW')],
      );
    }

    ChoiceChip chipWith(WidgetTester tester, String text) =>
        tester.widget<ChoiceChip>(find.ancestor(
          of: find.text(text),
          matching: find.byType(ChoiceChip),
        ));

    testWidgets('tag filter survives language switch', (tester) async {
      final app = await zhVm(tester);
      await tester.pumpWidget(liveLocaleApp(
          app, const Scaffold(body: PlayerSheet(initiallyExpanded: true))));
      await tester.pumpAndSettle();

      await tester.tap(find.text('四字彌陀 (12)'));
      await tester.pumpAndSettle();
      final zhCount = find.byType(SongListTile).evaluate().length;
      expect(zhCount, 12);

      app.locale.setAppLanguage(AppLanguage.en);
      await tester.pumpAndSettle();
      expect(chipWith(tester, '4-char Amitabha (12)').selected, isTrue);
      expect(chipWith(tester, 'All (31)').selected, isFalse);
      expect(find.byType(SongListTile).evaluate().length, zhCount);
      await disposeAndSettleTimers(tester);
    });

    testWidgets('english search matches localized titles', (tester) async {
      final app = await zhVm(tester);
      app.locale.setAppLanguage(AppLanguage.en);
      await tester.pumpWidget(liveLocaleApp(
          app, const Scaffold(body: PlayerSheet(initiallyExpanded: true))));
      await tester.pumpAndSettle();

      expect(find.text('Search title, master or tag...'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Ksitigarbha');
      await tester.pumpAndSettle();
      expect(find.byType(SongListTile), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pumpAndSettle();
      expect(find.text('No matching chants'), findsOneWidget);
      await disposeAndSettleTimers(tester);
    });
  });

  group('dedication view and guide dialog', () {
    testWidgets('practice view shows english dedication verses',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final app = AppControllers.create(
        storage: storage,
        audio: AudioService(),
        deviceLocales: const [Locale('zh', 'TW')],
      );
      app.locale.setAppLanguage(AppLanguage.en);
      await tester.pumpWidget(
          liveLocaleApp(app, const Scaffold(body: ModernPracticeView())));
      await tester.pump();
      await tester.pump();

      final en = chantContentFor(kEn).huiXiangItems.first;
      expect(find.text(en.title), findsOneWidget);
      expect(find.text(en.verses.first), findsOneWidget);
      expect(find.text('Namo Amitabha Buddha'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('guide dialog renders in Simplified Chinese', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final app = AppControllers.create(
        storage: storage,
        audio: AudioService(),
        deviceLocales: const [Locale('zh', 'CN')],
      );
      await tester.pumpWidget(liveLocaleApp(
          app, const Scaffold(body: Center(child: ModernGuideDialog()))));
      await tester.pump();
      expect(find.text('开始精进'), findsOneWidget);
      expect(find.text('每日功课表记'), findsOneWidget);
    });
  });

  group('classic mode screens', () {
    Future<AppControllers> enVm(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      await storage.setOrientationLocked(false);
      return AppControllers.create(
        storage: storage,
        audio: AudioService(),
        deviceLocales: const [Locale('en', 'GB')],
      );
    }

    testWidgets('legacy counter, settings and about render in English',
        (tester) async {
      final app = await enVm(tester);
      await tester.pumpWidget(liveLocaleApp(app, const LegacyCounterScreen()));
      await tester.pump();
      expect(find.text('Manual'), findsOneWidget);
      expect(find.text('Namo Amitabha Buddha'), findsWidgets);

      await tester.pumpWidget(liveLocaleApp(app, const LegacySettingsScreen()));
      await tester.pump();
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Wooden fish 1'), findsOneWidget);

      await tester.pumpWidget(liveLocaleApp(app, const LegacyAboutScreen()));
      await tester.pump();
      expect(find.text("A-Chung's Corner"), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeAndSettleTimers(tester);
    });

    test('sound effect labels exist in every language', () {
      for (final loc in [kZhHant, kZhHans, kEn]) {
        final l10n = lookupAppLocalizations(loc);
        for (final t in SoundEffectType.values) {
          expect(soundEffectLabel(l10n, t), isNotEmpty);
        }
      }
      expect(
          soundEffectLabel(
              lookupAppLocalizations(kZhHant), SoundEffectType.woodfish2),
          '木魚二 (經典原音)');
    });
  });

  group('services without BuildContext', () {
    test('home widget texts are localized and zh_Hant is unchanged', () {
      WidgetTexts build(Locale l, {int target = 108, int streak = 3}) =>
          buildWidgetTexts(
            lookupAppLocalizations(l),
            todayCount: 54,
            targetCount: target,
            weeklyCount: 300,
            monthlyCount: 1200,
            streakDays: streak,
            now: DateTime(2026, 11, 3),
          );

      final en = build(kEn);
      expect(en.streakText, '🔥 3-day streak');
      expect(en.targetText, 'Goal 50% (54/108)');
      expect(en.dateDisplay, 'Nov 3');
      expect(en.weeklyText, 'Week: 300');
      expect(en.widgetTitle, 'Buddha Counter');

      final zh = build(kZhHant);
      expect(zh.targetText, '目標 50% (54/108)');
      expect(zh.streakText, '🔥 連續 3 天');
      expect(zh.dateDisplay, '11月3日');
      expect(zh.weeklyText, '本週: 300聲');
      expect(build(kZhHant, target: 0).targetText, '今日累積 54 聲 (不限目標)');
      expect(build(kZhHant, streak: 0).streakText, '今日精進念佛');
    });

    test('home widget weekly/monthly keep thousands separators', () {
      final zh = buildWidgetTexts(lookupAppLocalizations(kZhHant),
          todayCount: 0,
          targetCount: 0,
          weeklyCount: 12345,
          monthlyCount: 1234567,
          streakDays: 0,
          now: DateTime(2026, 1, 1));
      expect(zh.weeklyText, '本週: 12,345聲');
      expect(zh.monthlyText, '本月: 1,234,567聲');
      final en = buildWidgetTexts(lookupAppLocalizations(kEn),
          todayCount: 0,
          targetCount: 0,
          weeklyCount: 12345,
          monthlyCount: 0,
          streakDays: 0,
          now: DateTime(2026, 1, 1));
      expect(en.weeklyText, 'Week: 12,345');
    });

    test('language change is pushed to records and notifications', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final notifications = NotificationService(storage);
      final app = AppControllers.create(
        storage: storage,
        audio: AudioService(),
        notifications: notifications,
        deviceLocales: const [Locale('zh', 'TW')],
      );
      expect(app.practice.records.locale, kZhHant);
      expect(notifications.locale, kZhHant);
      app.locale.setAppLanguage(AppLanguage.en);
      expect(app.practice.records.locale, kEn);
      expect(notifications.locale, kEn);
    });

    testWidgets(
        'switching language while auto counting keeps counting and refreshes media item',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final handler = _RefreshCountingHandler();
      final app = AppControllers.create(
        storage: storage,
        audio: AudioService(handler: handler),
        deviceLocales: const [Locale('zh', 'TW')],
      );
      final markers = ChantConstants.getSongById(app.playback.currentSongId)
          .phraseMarkersMs;
      Future<void> emit(int ms) async {
        handler.positions.add(Duration(milliseconds: ms));
        await tester.pump();
      }

      app.autoCount.clearStopCondition();
      app.practice.resetAutoCount();
      app.autoCount.start();
      await tester.pump();
      await emit(0);
      await emit(markers[0] + 10);
      await emit(markers[1] + 10);
      expect(app.practice.autoCount, 2);

      final before = handler.refreshCalls;
      app.locale.setAppLanguage(AppLanguage.en);
      await tester.pump();
      expect(app.autoCount.isCounting, isTrue);
      expect(handler.refreshCalls, before + 1);
      expect(handler.queue.value.first.title, contains('Amitabha'));
      if (handler.mediaItem.value != null) {
        expect(handler.mediaItem.value!.title, contains('Amitabha'));
      }

      await emit(markers[2] + 10);
      expect(app.practice.autoCount, 3);
      app.autoCount.stop();
      app.dispose();
    });
  });

  group('narrow layout (320dp) in every language', () {
    var realFont = false;
    setUpAll(() async {
      realFont = await loadRealLatinFont();
    });

    for (final lang in [
      AppLanguage.en,
      AppLanguage.zhHans,
      AppLanguage.zhHant
    ]) {
      testWidgets('no overflow in ${lang.storageValue}', (tester) async {
        if (!realFont) {
          markTestSkipped(
              'Flutter SDK Roboto not found; widths would be unrealistic');
          return;
        }
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({
          StorageService.keyAutoCounter: 9876,
          StorageService.keyCounter: 12345,
        });
        final storage = await StorageService.init();
        await storage.setSeenModernGuide(true);
        await storage.setOrientationLocked(false);
        final app = AppControllers.create(
          storage: storage,
          audio: AudioService(),
          deviceLocales: const [Locale('zh', 'TW')],
        );
        app.locale.setAppLanguage(lang);
        app.autoCount.setTargetCount(10000);
        app.practice.setTargetCount(10000);
        app.settings.setUiMode(AppUiMode.modern);

        await tester
            .pumpWidget(liveLocaleApp(app, const ModernCounterScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'manual tab');

        final nav = find.byType(NavigationDestination);
        for (var i = 1; i < 4; i++) {
          await tester.tap(nav.at(i));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'tab $i');
        }

        await tester.pumpWidget(
            liveLocaleApp(app, const Scaffold(body: ModernTimerView())));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'auto count view');

        app.settings.setUiMode(AppUiMode.legacy);
        await tester
            .pumpWidget(liveLocaleApp(app, const LegacyCounterScreen()));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'legacy counter');

        await tester
            .pumpWidget(liveLocaleApp(app, const LegacySettingsScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'legacy settings');
        await disposeAndSettleTimers(tester);
      });
    }
  });

  group('language picker', () {
    Future<AppControllers> newVm() async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      await storage.setSeenModernGuide(true);
      return AppControllers.create(
        storage: storage,
        audio: AudioService(),
        deviceLocales: const [Locale('zh', 'TW')],
      );
    }

    void useTallScreen(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('drawer language item switches app to English and back',
        (tester) async {
      useTallScreen(tester);
      final app = await newVm();
      app.settings.setUiMode(AppUiMode.modern);
      await tester.pumpWidget(liveLocaleApp(app, const ModernCounterScreen()));
      await tester.pumpAndSettle();

      tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
      await tester.pumpAndSettle();
      await tester.tap(find.text('語言'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(app.locale.appLanguage, AppLanguage.en);
      expect(find.text('Language'), findsOneWidget);

      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('繁體中文'));
      await tester.pumpAndSettle();
      expect(app.locale.appLanguage, AppLanguage.zhHant);
      expect(find.text('語言'), findsOneWidget);
      await disposeAndSettleTimers(tester);
    });

    testWidgets('legacy settings language section switches to Simplified',
        (tester) async {
      useTallScreen(tester);
      final app = await newVm();
      await tester.pumpWidget(liveLocaleApp(app, const LegacySettingsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('語言'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(RadioListTile<AppLanguage>, '跟隨系統'),
        findsOneWidget,
      );
      await tester.tap(find.text('简体中文'));
      await tester.pumpAndSettle();

      expect(app.locale.appLanguage, AppLanguage.zhHans);
      expect(find.text('语言'), findsOneWidget);
    });
  });
}

/// 可推送播放進度並記錄 refreshMediaItems 呼叫次數的音訊處理器
class _RefreshCountingHandler extends ChantAudioHandler {
  final StreamController<Duration> positions =
      StreamController<Duration>.broadcast();
  int refreshCalls = 0;

  @override
  Stream<Duration> get onPositionChanged => positions.stream;

  @override
  void refreshMediaItems(AppLocalizations l10n) {
    refreshCalls++;
    super.refreshMediaItems(l10n);
  }
}
