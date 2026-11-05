import 'package:buddha_counter/app/app_controllers.dart';
import 'package:buddha_counter/core/platform/app_platform.dart';
import 'package:buddha_counter/core/services/audio_service.dart';
import 'package:buddha_counter/core/services/storage_service.dart';
import 'package:buddha_counter/ui/common/tablet_scale.dart';
import 'package:buddha_counter/ui/modern/screens/modern_counter_screen.dart';
import 'package:buddha_counter/ui/modern/widgets/modern_floating_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_app.dart';

void main() {
  setUpTestPlatformMocks();

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(
        {StorageService.keySeenModernGuide: true});
    final storage = await StorageService.init();
    final app = AppControllers.create(storage: storage, audio: AudioService());
    await tester.pumpWidget(
        app.provide(child: testApp(home: const ModernCounterScreen())));
    await tester.pump();
  }

  testWidgets('iPad: content is limited to a readable width and centred',
      (tester) async {
    await pumpAt(tester, const Size(1032, 1376));

    for (final finder in [
      find.byType(PageView),
      find.byType(ModernFloatingPlayer),
    ]) {
      final rect = tester.getRect(finder);
      expect(rect.width, ModernCounterScreen.maxContentWidth);
      expect(rect.center.dx, closeTo(1032 / 2, 0.5));
    }
    // 導覽列維持整個寬度
    expect(tester.getSize(find.byType(NavigationBar)).width, 1032);
    await disposeAndSettleTimers(tester);
  });

  group('TabletScale', tabletScaleTests);

  testWidgets('phone: content still uses the full width', (tester) async {
    await pumpAt(tester, const Size(400, 860));
    expect(tester.getSize(find.byType(PageView)).width, 400);
    await disposeAndSettleTimers(tester);
  });
}

// 以下測 TabletScale：平板上整個 App 等比放大，版面當作「大手機」排
void tabletScaleTests() {
  Future<(Size, Size)> layoutAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late Size logical;
    await tester.pumpWidget(MediaQuery(
      data: MediaQueryData(size: size),
      child: TabletScale(
        child: Builder(builder: (context) {
          logical = MediaQuery.sizeOf(context);
          return const SizedBox.expand(key: ValueKey('content'));
        }),
      ),
    ));
    final painted = tester.getSize(find.byKey(const ValueKey('content')));
    return (logical, painted);
  }

  testWidgets('phone: no scaling', (tester) async {
    final (logical, painted) = await layoutAt(tester, const Size(400, 860));
    expect(logical, const Size(400, 860));
    expect(painted, const Size(400, 860));
  });

  testWidgets('iPad 13": laid out at 1/1.5 size and scaled to fill the screen',
      (tester) async {
    final (logical, _) = await layoutAt(tester, const Size(1032, 1376));
    expect(logical.width, closeTo(1032 / 1.5, 0.01));
    expect(logical.height, closeTo(1376 / 1.5, 0.01));
    // 放大後剛好填滿整個畫面
    final rect = tester.getRect(find.byKey(const ValueKey('content')));
    expect(rect.size.width, closeTo(1032, 0.5));
    expect(rect.size.height, closeTo(1376, 0.5));
  });

  testWidgets('iPad 11": scale follows the shortest side', (tester) async {
    final (logical, _) = await layoutAt(tester, const Size(834, 1194));
    expect(logical.width, closeTo(600, 0.01));
  });

  testWidgets('web: never scaled (WebFrame handles wide screens)',
      (tester) async {
    AppPlatform.debugIsWebOverride = true;
    addTearDown(() => AppPlatform.debugIsWebOverride = null);
    final (logical, _) = await layoutAt(tester, const Size(1032, 1376));
    expect(logical, const Size(1032, 1376));
  });
}
