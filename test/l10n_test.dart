import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buddha_counter/core/services/audio_service.dart';
import 'package:buddha_counter/core/services/storage_service.dart';
import 'package:buddha_counter/features/counter/counter_view_model.dart';
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
import 'package:buddha_counter/ui/modern/views/modern_player_view.dart';
import 'package:buddha_counter/ui/modern/widgets/song_list_tile.dart';
import 'package:buddha_counter/ui/modern/views/modern_practice_view.dart';
import 'package:buddha_counter/ui/modern/widgets/modern_guide_dialog.dart';
import 'package:buddha_counter/ui/legacy/screens/legacy_counter_screen.dart';
import 'package:buddha_counter/ui/legacy/screens/legacy_about_screen.dart';
import 'package:buddha_counter/l10n/sound_effect_labels.dart';

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
      final vm = CounterViewModel(
        storage: storage,
        audio: AudioService(),
        deviceLocales: device,
      );
      expect(vm.appLanguage, AppLanguage.system);
      expect(vm.locale, kEn);

      vm.setAppLanguage(AppLanguage.zhHans);
      expect(vm.locale, kZhHans);

      final vm2 = CounterViewModel(
        storage: storage,
        audio: AudioService(),
        deviceLocales: device,
      );
      expect(vm2.appLanguage, AppLanguage.zhHans);
      expect(vm2.locale, kZhHans);
      expect(storage.getAppLanguage(), AppLanguage.zhHans);

      vm2.setAppLanguage(AppLanguage.system);
      vm2.updateDeviceLocales(const [Locale('zh', 'HK')]);
      expect(vm2.locale, kZhHant);
    });
  });

  group('modern shell and manual counter', () {
    Future<CounterViewModel> vmFor(Locale device) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      await storage.setSeenModernGuide(true);
      return CounterViewModel(
        storage: storage,
        audio: AudioService(),
        deviceLocales: [device],
      );
    }

    testWidgets('manual counter renders in en and zh_Hans', (tester) async {
      final vm = await vmFor(const Locale('en'));
      await tester.pumpWidget(
          liveLocaleApp(vm, const Scaffold(body: ModernCounterView())));
      await tester.pump();
      expect(find.text('Goal 108'), findsOneWidget);
      expect(find.text('Goal 108 · 0%'), findsOneWidget);

      vm.setAppLanguage(AppLanguage.zhHans);
      await tester.pumpAndSettle();
      expect(find.text('目标 108'), findsOneWidget);
      expect(find.text('声 · 拜'), findsOneWidget);
    });

    testWidgets('bottom tabs are localized in English', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final vm = await vmFor(const Locale('en'));
      vm.setUiMode(AppUiMode.modern);
      await tester.pumpWidget(liveLocaleApp(vm, const ModernCounterScreen()));
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
      final vm = CounterViewModel(
        storage: storage,
        audio: AudioService(),
        deviceLocales: const [Locale('en', 'US')],
      );
      vm.setAutoTargetCount(108);
      await tester.pumpWidget(
          liveLocaleApp(vm, const Scaffold(body: ModernTimerView())));
      await tester.pump();

      expect(find.text('Goal 108'), findsOneWidget);
      expect(find.text('Goal 108 · 25%'), findsOneWidget);
      expect(find.text('−1'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);

      vm.setAutoStopMinutes(30);
      await tester.pump();
      expect(find.text('30 min'), findsOneWidget);
      expect(find.text('Timer 30 min · 30 min left'), findsOneWidget);

      vm.clearAutoStopCondition();
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
      final vm = CounterViewModel(
        storage: storage,
        audio: AudioService(),
        deviceLocales: const [Locale('en')],
      );
      await tester.pumpWidget(
          liveLocaleApp(vm, const Scaffold(body: ModernCalendarView())));
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
      expect(chantTagLabel(lookupAppLocalizations(kZhHant),
          ChantTag.fourCharAmitabha), '四字彌陀');
    });

    test('view model applies content locale on language change', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final vm = CounterViewModel(
        storage: storage,
        audio: AudioService(),
        deviceLocales: const [Locale('zh', 'TW')],
      );
      expect(ChantConstants.huiXiangItems.first.title, '大回向西方文');
      vm.setAppLanguage(AppLanguage.zhHans);
      expect(ChantConstants.huiXiangItems.first.verses.first,
          startsWith('愿我临终'));
    });
  });

  group('player and song lists', () {
    Future<CounterViewModel> zhVm(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      return CounterViewModel(
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
      final vm = await zhVm(tester);
      await tester.pumpWidget(
          liveLocaleApp(vm, const Scaffold(body: ModernPlayerView())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('四字彌陀 (12)'));
      await tester.pumpAndSettle();
      final zhCount = find.byType(SongListTile).evaluate().length;
      expect(zhCount, 12);

      vm.setAppLanguage(AppLanguage.en);
      await tester.pumpAndSettle();
      expect(chipWith(tester, '4-char Amitabha (12)').selected, isTrue);
      expect(chipWith(tester, 'All (31)').selected, isFalse);
      expect(find.byType(SongListTile).evaluate().length, zhCount);
      await disposeAndSettleTimers(tester);
    });

    testWidgets('english search matches localized titles', (tester) async {
      final vm = await zhVm(tester);
      vm.setAppLanguage(AppLanguage.en);
      await tester.pumpWidget(
          liveLocaleApp(vm, const Scaffold(body: ModernPlayerView())));
      await tester.pumpAndSettle();

      expect(find.text('Search 31 chants...'), findsOneWidget);
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
      final vm = CounterViewModel(
        storage: storage,
        audio: AudioService(),
        deviceLocales: const [Locale('zh', 'TW')],
      );
      vm.setAppLanguage(AppLanguage.en);
      await tester.pumpWidget(
          liveLocaleApp(vm, const Scaffold(body: ModernPracticeView())));
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
      final vm = CounterViewModel(
        storage: storage,
        audio: AudioService(),
        deviceLocales: const [Locale('zh', 'CN')],
      );
      await tester.pumpWidget(liveLocaleApp(
          vm, const Scaffold(body: Center(child: ModernGuideDialog()))));
      await tester.pump();
      expect(find.text('开始精进'), findsOneWidget);
      expect(find.text('每日功课表记'), findsOneWidget);
    });
  });

  group('classic mode screens', () {
    Future<CounterViewModel> enVm(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      await storage.setOrientationLocked(false);
      return CounterViewModel(
        storage: storage,
        audio: AudioService(),
        deviceLocales: const [Locale('en', 'GB')],
      );
    }

    testWidgets('legacy counter, settings and about render in English',
        (tester) async {
      final vm = await enVm(tester);
      await tester.pumpWidget(liveLocaleApp(vm, const LegacyCounterScreen()));
      await tester.pump();
      expect(find.text('Manual'), findsOneWidget);
      expect(find.text('Namo Amitabha Buddha'), findsWidgets);

      await tester.pumpWidget(liveLocaleApp(vm, const LegacySettingsScreen()));
      await tester.pump();
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Wooden fish 1'), findsOneWidget);

      await tester.pumpWidget(liveLocaleApp(vm, const LegacyAboutScreen()));
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
      expect(soundEffectLabel(lookupAppLocalizations(kZhHant),
          SoundEffectType.woodfish2), '木魚二 (經典原音)');
    });
  });

  group('language picker', () {
    Future<CounterViewModel> newVm() async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      await storage.setSeenModernGuide(true);
      return CounterViewModel(
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
      final vm = await newVm();
      vm.setUiMode(AppUiMode.modern);
      await tester.pumpWidget(liveLocaleApp(vm, const ModernCounterScreen()));
      await tester.pumpAndSettle();

      tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
      await tester.pumpAndSettle();
      await tester.tap(find.text('語言'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(vm.appLanguage, AppLanguage.en);
      expect(find.text('Language'), findsOneWidget);

      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('繁體中文'));
      await tester.pumpAndSettle();
      expect(vm.appLanguage, AppLanguage.zhHant);
      expect(find.text('語言'), findsOneWidget);
      await disposeAndSettleTimers(tester);
    });

    testWidgets('legacy settings language section switches to Simplified',
        (tester) async {
      useTallScreen(tester);
      final vm = await newVm();
      await tester.pumpWidget(liveLocaleApp(vm, const LegacySettingsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('語言'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(RadioListTile<AppLanguage>, '跟隨系統'),
        findsOneWidget,
      );
      await tester.tap(find.text('简体中文'));
      await tester.pumpAndSettle();

      expect(vm.appLanguage, AppLanguage.zhHans);
      expect(find.text('语言'), findsOneWidget);
    });
  });
}
