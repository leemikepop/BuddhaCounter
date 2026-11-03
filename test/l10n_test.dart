import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buddha_counter/core/services/audio_service.dart';
import 'package:buddha_counter/core/services/storage_service.dart';
import 'package:buddha_counter/features/counter/counter_view_model.dart';
import 'package:buddha_counter/l10n/l10n.dart';
import 'package:buddha_counter/ui/legacy/screens/legacy_settings_screen.dart';
import 'package:buddha_counter/ui/modern/screens/modern_counter_screen.dart';

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
