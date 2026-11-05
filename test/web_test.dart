import 'package:buddha_counter/app/app_controllers.dart';
import 'package:buddha_counter/core/platform/app_platform.dart';
import 'package:buddha_counter/core/services/audio_service.dart';
import 'package:buddha_counter/core/services/storage_service.dart';
import 'package:buddha_counter/l10n/l10n.dart';
import 'package:buddha_counter/ui/common/screen_toggle_buttons.dart';
import 'package:buddha_counter/ui/modern/views/calendar/goal_reminder_card.dart';
import 'package:buddha_counter/ui/web/web_frame.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_app.dart';

/// 網頁版的外框與功能隱藏 (用 AppPlatform.debugIsWebOverride 模擬在瀏覽器執行)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpTestPlatformMocks();

  tearDown(() {
    AppPlatform.debugIsWebOverride = null;
    debugDefaultTargetPlatformOverride = null;
  });

  /// 在指定大小的視窗裡掛上 WebFrame (與 MaterialApp.builder 相同位置)，回報內部看到的寬度
  Future<double> pumpFramed(WidgetTester tester, Size window) async {
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late double seenWidth;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: kZhHant,
      builder: (context, child) => WebFrame(child: child!),
      home: Builder(builder: (context) {
        seenWidth = MediaQuery.sizeOf(context).width;
        return const Scaffold(body: Text('home'));
      }),
    ));
    return seenWidth;
  }

  group('WebFrame', () {
    testWidgets('native apps are not framed', (tester) async {
      AppPlatform.debugIsWebOverride = false;
      expect(await pumpFramed(tester, const Size(1280, 800)), 1280);
      expect(find.byType(GetAppBanner), findsNothing);
    });

    testWidgets('a wide desktop browser keeps the app at phone width',
        (tester) async {
      AppPlatform.debugIsWebOverride = true;
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(
          await pumpFramed(tester, const Size(1280, 800)), WebFrame.phoneWidth);
      expect(tester.getSize(find.byType(Scaffold)).width, WebFrame.phoneWidth);
      expect(find.byType(GetAppBanner), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('a narrow browser window uses its full width', (tester) async {
      AppPlatform.debugIsWebOverride = true;
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(await pumpFramed(tester, const Size(400, 800)), 400);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('phone browsers suggest the store for that phone, dismissible',
        (tester) async {
      AppPlatform.debugIsWebOverride = true;
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await pumpFramed(tester, const Size(390, 844));

      expect(find.text('App Store'), findsOneWidget);
      expect(find.text('Google Play'), findsNothing);
      expect(find.text('home'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(find.text('App Store'), findsNothing);
      expect(find.text('home'), findsOneWidget);
      // 平台覆寫必須在測試本體結束前還原 (框架會在 tearDown 前檢查)
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('features hidden on the web', () {
    late AppControllers app;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      app = AppControllers.create(
          storage: await StorageService.init(), audio: AudioService());
    });

    tearDown(() => app.dispose());

    Widget wrap(Widget child) => app.provide(
          child: testApp(
              home: Scaffold(body: SingleChildScrollView(child: child))),
        );

    testWidgets(
        'calendar card keeps the daily goal but drops reminder and widget',
        (tester) async {
      final l10n = lookupAppLocalizations(kZhHant);

      AppPlatform.debugIsWebOverride = false;
      await tester.pumpWidget(wrap(const GoalReminderCard()));
      expect(find.text(l10n.reminderTitle), findsOneWidget);
      expect(find.text(l10n.widgetCardTitle), findsOneWidget);

      AppPlatform.debugIsWebOverride = true;
      await tester
          .pumpWidget(wrap(const GoalReminderCard(key: ValueKey('web'))));
      expect(find.text(l10n.reminderTitle), findsNothing);
      expect(find.text(l10n.widgetCardTitle), findsNothing);
      expect(find.text(l10n.dailyGoalRowTitle), findsOneWidget,
          reason: 'the daily goal row stays');
    });

    testWidgets('orientation lock button is not shown in a browser',
        (tester) async {
      AppPlatform.debugIsWebOverride = true;
      await tester.pumpWidget(wrap(const OrientationLockButton()));
      expect(find.byType(IconButton), findsNothing);

      AppPlatform.debugIsWebOverride = false;
      await tester
          .pumpWidget(wrap(const OrientationLockButton(key: ValueKey('n'))));
      expect(find.byType(IconButton), findsOneWidget);
    });
  });
}
