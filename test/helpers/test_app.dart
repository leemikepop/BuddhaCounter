import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:buddha_counter/app/app_controllers.dart';
import 'package:buddha_counter/core/constants/chant_songs.dart';
import 'package:buddha_counter/features/settings/locale_controller.dart';
import 'package:buddha_counter/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 測試用 MaterialApp：已掛好多語言 delegates，預設固定為繁體中文
Widget testApp({required Widget home, Locale locale = kZhHant}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: home,
  );
}

/// 測試用 App：語言跟隨 [LocaleController] 即時切換 (用於驗證 App 內切換語言)
Widget liveLocaleApp(AppControllers app, Widget home) {
  return app.provide(
    child: Selector<LocaleController, Locale>(
      selector: (_, l) => l.locale,
      builder: (_, locale, __) => testApp(home: home, locale: locale),
    ),
  );
}

/// 註冊所有測試共用的平台通道 Mock (音訊、背景播放、路徑、套件資訊)
/// 並固定每個測試的手機語言為 zh-TW、曲目內容為繁中 (避免全域內容狀態在測試間殘留)
void setUpTestPlatformMocks() {
  setUp(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.localesTestValue =
        const [Locale('zh', 'TW')];
    ChantConstants.applyLocale(kZhHant);
  });
  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearLocalesTestValue();
  });

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
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (call) async => 1,
    );
    messenger.setMockMethodCallHandler(
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
            messenger.handlePlatformMessage(eventChannel, message, (data) {});
          } else if (call.method == 'setSourceUrl' ||
              call.method == 'setSourceBytes') {
            final ByteData message =
                const StandardMethodCodec().encodeSuccessEnvelope({
              'event': 'audio.onPrepared',
              'value': true,
            });
            messenger.handlePlatformMessage(eventChannel, message, (data) {});
          }
        }
        return 1;
      },
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.audio_service.client.methods'),
      (call) async => {},
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.audio_service.handler.methods'),
      (call) async => {},
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.path,
    );
  });
}

/// 卸載畫面並推進時間，讓跑馬燈 (MarqueeText) 等延遲迴圈自然結束，避免 pending timer
Future<void> disposeAndSettleTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}

/// 載入 Flutter SDK 內附的 Roboto，讓拉丁字母與數字以真實字寬排版。
/// (測試預設字型每個字元都是 1em 方塊，英文與數字寬度會被高估約一倍；中文則本來就接近 1em)
/// 找不到 SDK 字型時回傳 false，呼叫端應略過依賴真實字寬的測試。
Future<bool> loadRealLatinFont() async {
  final candidates = <String>[
    if (Platform.environment['FLUTTER_ROOT'] != null)
      Platform.environment['FLUTTER_ROOT']!,
  ];
  // flutter_tester 位於 <FLUTTER_ROOT>/bin/cache/artifacts/engine/...
  final exe = Platform.resolvedExecutable.replaceAll(r'\', '/');
  final idx = exe.indexOf('/bin/cache/');
  if (idx > 0) candidates.add(exe.substring(0, idx));

  for (final root in candidates) {
    final dir = Directory('$root/bin/cache/artifacts/material_fonts');
    final regular = File('${dir.path}/roboto-regular.ttf');
    if (!regular.existsSync()) continue;
    final loader = FontLoader('Roboto');
    for (final name in ['regular', 'medium', 'bold']) {
      final f = File('${dir.path}/roboto-$name.ttf');
      if (f.existsSync()) {
        final bytes = f.readAsBytesSync();
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      }
    }
    await loader.load();
    return true;
  }
  return false;
}
