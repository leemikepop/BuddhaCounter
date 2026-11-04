import 'package:buddha_counter/app/app_controllers.dart';
import 'package:buddha_counter/core/services/audio_service.dart';
import 'package:buddha_counter/core/services/storage_service.dart';
import 'package:buddha_counter/features/playback/playback_controller.dart';
import 'package:buddha_counter/ui/legacy/screens/legacy_chant_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_app.dart';

/// 經典模式迴向頁：進入自動播放、離開停止
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpTestPlatformMocks();

  testWidgets('plays on enter and stops when the page goes away',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final app = AppControllers.create(storage: storage, audio: AudioService());
    await tester.pumpWidget(app.provide(
      child: testApp(
        home: Column(children: [
          Selector<PlaybackController, bool>(
            selector: (_, p) => p.isPlaying,
            builder: (_, playing, __) => Text('$playing'),
          ),
          const Expanded(child: LegacyChantScreen()),
        ]),
      ),
    ));
    await tester.pump();
    expect(app.playback.isPlaying, isTrue);

    // 頁面被移除 (例如整個畫面樹被替換) 時也要停止，且不能在框架鎖定期間通知重繪
    await tester.pumpWidget(app.provide(
      child: testApp(
        home: Selector<PlaybackController, bool>(
          selector: (_, p) => p.isPlaying,
          builder: (_, playing, __) => Text('$playing'),
        ),
      ),
    ));
    await tester.pump();
    expect(app.playback.isPlaying, isFalse);
    expect(find.text('false'), findsOneWidget);
    app.dispose();
  });
}
