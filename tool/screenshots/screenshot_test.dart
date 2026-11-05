// 商店 / README 截圖產生器。
//
//   bash tool/screenshots/fetch_fonts.sh                 # 第一次：下載 Noto Sans 字型
//   flutter test tool/screenshots/screenshot_test.dart   # 輸出到 build/screenshots/
//
// 以真實 App 根元件 (BuddhaCounterApp) 加上示範資料繪製，再以裝置解析度存成 PNG。
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:buddha_counter/app/app_controllers.dart';
import 'package:buddha_counter/app/buddha_counter_app.dart';
import 'package:buddha_counter/core/services/audio_service.dart';
import 'package:buddha_counter/core/services/practice_record_service.dart';
import 'package:buddha_counter/core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test/helpers/test_app.dart';

const _outDir = 'build/screenshots';

/// 截圖裝置：邏輯尺寸 × 像素比 = 商店要求的像素
class Device {
  const Device(this.name, this.logicalSize, this.pixelRatio);
  final String name;
  final Size logicalSize;
  final double pixelRatio;
}

const iPhone69 = Device('iphone_6.9', Size(440, 956), 3); // 1320×2868

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    final bytes = File(p).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

String _sdkMaterialFonts() {
  final exe = Platform.resolvedExecutable.replaceAll(r'\', '/');
  final root = Platform.environment['FLUTTER_ROOT'] ??
      exe.substring(0, exe.indexOf('/bin/cache/'));
  return '$root/bin/cache/artifacts/material_fonts';
}

Future<void> _loadFonts() async {
  const fonts = 'tool/screenshots/fonts';
  if (!File('$fonts/NotoSansTC-Regular.otf').existsSync()) {
    fail('找不到字型，請先執行 bash tool/screenshots/fetch_fonts.sh');
  }
  final sdk = _sdkMaterialFonts();
  await _loadFont('MaterialIcons', ['$sdk/materialicons-regular.otf']);
  // flutter_tester 不會逐字改用其他字型 (缺字只會畫方框)，所以把 Noto Sans TC 直接註冊成
  // 主題使用的字型名稱 Roboto：中文、英文與數字都用 Noto 排版。只影響截圖，不影響 App。
  // (沒指定字型的文字會用 flutter_tester 內建、無法替換的測試字型，所以主題裡每個樣式都要有字型)
  await _loadFont('Roboto', [
    for (final w in ['Regular', 'Medium', 'Bold']) '$fonts/NotoSansTC-$w.otf',
  ]);
}

/// 示範資料：今天念了 56 聲 (目標 108)，過去兩週有每日紀錄
Map<String, Object> _demoPrefs() {
  final now = DateTime.now();
  final records = <String, Object>{};
  for (var i = 1; i <= 14; i++) {
    final day = now.subtract(Duration(days: i));
    final manual = 108 + (i * 37) % 200;
    final auto = (i % 3 == 0) ? 0 : 300 + (i * 53) % 500;
    records[PracticeRecordService.formatDateKey(day)] = {
      'manual': manual,
      'auto': auto,
      'total': manual + auto,
    };
  }
  final today = PracticeRecordService.formatDateKey(now);
  records[today] = {'manual': 56, 'auto': 0, 'total': 56};
  return {
    StorageService.keyUiMode: 'modern',
    StorageService.keySeenModernGuide: true,
    StorageService.keyCounter: 56,
    StorageService.keyTargetCount: 108,
    StorageService.keyDailyTargetCount: 1080,
    StorageService.keyLastActiveDate: today,
    StorageService.keyDailyRecords: jsonEncode(records),
  };
}

Future<void> _capture(
    WidgetTester tester, Key key, String name, Device d) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: d.pixelRatio);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_outDir/${d.name}/$name.png')
      ..createSync(recursive: true);
    file.writeAsBytesSync(png!.buffer.asUint8List());
    // ignore: avoid_print
    print('wrote ${file.path} (${image.width}×${image.height})');
  });
}

void main() {
  setUpTestPlatformMocks();

  setUpAll(() async {
    // 音訊的 EventChannel 沒有原生端，給一個不發事件的 handler，避免 MissingPluginException
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in [
      'buddha_counter/chant_loop_player/events',
      'xyz.luan/audioplayers.global/events',
      for (var i = 0; i < 6; i++) 'xyz.luan/audioplayers/events/sfx_pool_$i',
    ]) {
      messenger.setMockStreamHandler(
          EventChannel(name), MockStreamHandler.inline(onListen: (_, __) {}));
    }
    await _loadFonts();
  });

  testWidgets('manual count', (tester) async {
    const d = iPhone69;
    tester.view.physicalSize = d.logicalSize * d.pixelRatio;
    tester.view.devicePixelRatio = d.pixelRatio;
    addTearDown(tester.view.reset);

    // tool/ 不算測試目錄，分析器不知道這是測試
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues(_demoPrefs());
    final storage = await StorageService.init();
    final app = AppControllers.create(storage: storage, audio: AudioService());

    const key = ValueKey('shot');
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: app.provide(child: const BuddhaCounterApp()),
    ));
    await tester.pumpAndSettle();

    await _capture(tester, key, 'zh_Hant_01_manual', d);
    await disposeAndSettleTimers(tester);
  });
}
