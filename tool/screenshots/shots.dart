// 商店 / README 截圖產生器的共用部分 (每個語言一個 *_test.dart 進入點)。
//
//   bash tool/screenshots/fetch_fonts.sh   # 第一次：下載 Noto Sans 字型
//   flutter test tool/screenshots          # 輸出到 build/screenshots/<裝置>/<語言>/
//
// 以真實 App 根元件 (BuddhaCounterApp) 加上示範資料繪製，再以裝置解析度存成 PNG。
// 每個語言要用不同的中文字型，而字型註冊後整個行程都會沿用，所以每個語言各自一個測試檔
// (flutter test 會為每個測試檔開一個獨立的行程)。
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:buddha_counter/app/app_controllers.dart';
import 'package:buddha_counter/app/buddha_counter_app.dart';
import 'package:buddha_counter/core/services/audio_service.dart';
import 'package:buddha_counter/core/services/practice_record_service.dart';
import 'package:buddha_counter/core/services/storage_service.dart';
import 'package:buddha_counter/l10n/app_language.dart';
import 'package:buddha_counter/l10n/generated/app_localizations.dart';
import 'package:buddha_counter/ui/common/marquee_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

import '../../test/helpers/test_app.dart';
import 'posters.dart';

const outDir = 'build/screenshots';
const fontDir = 'tool/screenshots/fonts';

/// 截圖裝置：邏輯尺寸 × 像素比 = 商店要求的像素
class Device {
  const Device(this.name, this.logicalSize, this.pixelRatio);
  final String name;
  final Size logicalSize;
  final double pixelRatio;
}

const devices = [
  Device('iphone_6.9', Size(440, 956), 3), // 1320×2868 (App Store 6.9 吋)
  Device('ipad_13', Size(1032, 1376), 2), // 2064×2752 (App Store 13 吋)
  Device('android_phone', Size(432, 768), 2.5), // 1080×1920 (Google Play 9:16)
];

/// 截圖語言：App 語言設定值 + 排版用的 Noto 字型
class ShotLocale {
  const ShotLocale(this.name, this.storageValue, this.locale, this.font);
  final String name;
  final String storageValue;
  final Locale locale;
  final String font; // NotoSansTC / NotoSansSC
}

const zhHant = ShotLocale('zh_Hant', 'zh_Hant', kZhHant, 'NotoSansTC');
const zhHans = ShotLocale('zh_Hans', 'zh_Hans', kZhHans, 'NotoSansSC');
// 英文介面裡仍有中文 (演唱者名稱)，所以也用含拉丁字母的 Noto Sans TC
const en = ShotLocale('en', 'en', kEn, 'NotoSansTC');

/// 一張截圖：要用哪個介面 / 主題，以及畫面開好後要做的操作
class Shot {
  const Shot(this.name,
      {this.legacy = false,
      this.dark = false,
      this.tab,
      this.openSongs = false});
  final String name;
  final bool legacy;
  final bool dark;
  final int? tab; // 現代模式的分頁 (ModernCounterScreen.*Tab)
  final bool openSongs; // 打開佛曲清單
}

const shots = [
  Shot('01_manual'),
  Shot('02_auto', tab: 1),
  Shot('03_songs', openSongs: true),
  Shot('04_dedication', tab: 2),
  Shot('05_calendar', tab: 3),
  Shot('06_classic', legacy: true),
  Shot('07_manual_dark', dark: true),
  Shot('08_calendar_dark', dark: true, tab: 3),
];

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    final bytes = File(p).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Future<void> _loadFonts(ShotLocale l) async {
  final serif = l.font.replaceFirst('Sans', 'Serif');
  if (!File('$fontDir/${l.font}-Regular.otf').existsSync() ||
      !File('$fontDir/$serif-Bold.otf').existsSync()) {
    fail('找不到字型，請先執行 bash tool/screenshots/fetch_fonts.sh');
  }
  // Material Icons：flutter test 會把它打包進測試資源 (uses-material-design: true)，
  // 不要去讀 SDK 快取 (CI 上的 Flutter 沒有 bin/cache/artifacts/material_fonts/)
  await (FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
      .load();
  // flutter_tester 不會逐字改用其他字型 (缺字只會畫方框)，所以把 Noto 直接註冊成
  // 主題使用的字型名稱 Roboto：中文、英文與數字都用 Noto 排版。只影響截圖，不影響 App。
  // (沒指定字型的文字會用 flutter_tester 內建、無法替換的測試字型，所以主題裡每個樣式都要有字型)
  await _loadFont('Roboto', [
    for (final w in ['Regular', 'Medium', 'Bold']) '$fontDir/${l.font}-$w.otf',
  ]);
  // 宣傳圖標題用的明體 (posters.dart 的 posterSerif)
  await _loadFont(posterSerif, ['$fontDir/$serif-Bold.otf']);
}

/// 示範資料：今天手動 56 聲 (目標 108)、自動 238 聲；過去約一個半月幾乎天天有紀錄
Map<String, Object> _demoPrefs(ShotLocale l, Shot s) {
  final now = DateTime.now();
  final records = <String, Object>{};
  for (var i = 1; i <= 45; i++) {
    // 最近 21 天連續精進，更早偶爾空一天
    if (i > 21 && i % 6 == 0) continue;
    final manual = 108 + (i * 37) % 200;
    final auto = (i % 3 == 0) ? 0 : 300 + (i * 53) % 500;
    records[PracticeRecordService.formatDateKey(
        now.subtract(Duration(days: i)))] = {
      'manual': manual,
      'auto': auto,
      'total': manual + auto,
    };
  }
  final today = PracticeRecordService.formatDateKey(now);
  records[today] = {'manual': 56, 'auto': 238, 'total': 294};
  return {
    StorageService.keyUiMode: s.legacy ? 'legacy' : 'modern',
    StorageService.keyThemeMode: s.dark ? 'dark' : 'light',
    StorageService.keyAppLanguage: l.storageValue,
    StorageService.keySeenModernGuide: true,
    StorageService.keyCounter: 56,
    StorageService.keyAutoCounter: 238,
    StorageService.keyAutoElapsedSeconds: 238 * 4,
    StorageService.keyTargetCount: 108,
    StorageService.keyDailyTargetCount: 1080,
    StorageService.keyLastActiveDate: today,
    StorageService.keyDailyRecords: jsonEncode(records),
  };
}

/// 圖片 (例如迴向頁的西方三聖) 是非同步解碼的，假時鐘下等不到；用真時間把畫面上的圖都載完再截
Future<void> _settleImages(WidgetTester tester) async {
  final images = find.byType(Image);
  await tester.runAsync(() async {
    for (final element in images.evaluate()) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });
  await tester.pumpAndSettle();
}

/// 跑馬燈 (曲名) 依時間來回捲動，截圖前一律捲回開頭，每張圖才一致
Future<void> _resetMarquees(WidgetTester tester) async {
  final scrollables = find.descendant(
      of: find.byType(MarqueeText), matching: find.byType(Scrollable));
  for (final s in tester.stateList<ScrollableState>(scrollables)) {
    s.position.jumpTo(0);
  }
  await tester.pump();
}

/// 把 [key] 這個 RepaintBoundary 以 [pixelRatio] 存檔：`.jpg` 存成 JPEG (宣傳圖，紙紋用 PNG 太大)，
/// 其他存成 PNG
Future<void> capture(
    WidgetTester tester, Key key, String path, double pixelRatio) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final List<int> bytes;
    if (path.endsWith('.jpg')) {
      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      bytes = img.encodeJpg(
        img.Image.fromBytes(
          width: image.width,
          height: image.height,
          bytes: rgba!.buffer,
          numChannels: 4,
        ),
        quality: 90,
      );
    } else {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      bytes = png!.buffer.asUint8List();
    }
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
    // ignore: avoid_print
    print('wrote $path (${image.width}×${image.height})');
  });
}

/// 產生一個語言的所有截圖 (每個裝置 × 每張畫面)
void runScreenshots(ShotLocale l) {
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
    await _loadFonts(l);
  });

  for (final d in devices) {
    for (final s in shots) {
      testWidgets('${d.name} ${l.name} ${s.name}', (tester) async {
        tester.view.physicalSize = d.logicalSize * d.pixelRatio;
        tester.view.devicePixelRatio = d.pixelRatio;
        addTearDown(tester.view.reset);

        final app = await demoApp(l, s);
        const key = ValueKey('shot');
        await tester.pumpWidget(RepaintBoundary(
          key: key,
          child: app.provide(child: const BuddhaCounterApp()),
        ));
        await openShot(tester, l, s);

        await capture(tester, key, '$outDir/${d.name}/${l.name}/${s.name}.png',
            d.pixelRatio);
        await disposeAndSettleTimers(tester);
      });
    }
  }

  registerPosterTests(l);
}

/// 依 [Shot] 建立一套帶示範資料的 controller
Future<AppControllers> demoApp(ShotLocale l, Shot s) async {
  // tool/ 不算測試目錄，分析器不知道這是測試
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues(_demoPrefs(l, s));
  final storage = await StorageService.init();
  return AppControllers.create(storage: storage, audio: AudioService());
}

/// App 已經 pump 好之後：切到 [Shot] 指定的畫面，並等圖片、跑馬燈就定位
Future<void> openShot(WidgetTester tester, ShotLocale l, Shot s) async {
  final l10n = lookupAppLocalizations(l.locale);
  await tester.pumpAndSettle();
  if (s.tab != null) {
    await tester.tap(find.byType(NavigationDestination).at(s.tab!));
    await tester.pumpAndSettle();
  }
  if (s.openSongs) {
    await tester.tap(find.byTooltip(l10n.songMenuExpand));
    await tester.pumpAndSettle();
  }
  // 月初的月曆大半是空的 (未來的日子)，改看上個月
  if (s.tab == 3 && DateTime.now().day < 15) {
    await tester.tap(find.byTooltip(l10n.calendarPrevMonth));
    await tester.pumpAndSettle();
  }
  await _settleImages(tester);
  await _resetMarquees(tester);
}
