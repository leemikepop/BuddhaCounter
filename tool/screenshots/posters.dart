// 商店宣傳圖 (紙紋背景 + 標題 + 手機外框裡的真實 App)、README 橫幅與 GitHub 社群預覽圖。
// 由 shots.dart 的 runScreenshots 一起註冊，輸出到 build/screenshots/posters/。
import 'dart:io';
import 'dart:typed_data';

import 'package:buddha_counter/app/buddha_counter_app.dart';
import 'package:buddha_counter/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/helpers/test_app.dart';
import 'shots.dart';

/// 宣傳圖標題字型 (Noto Serif TC / SC Bold，由 shots.dart 載入)
const posterSerif = 'PosterSerif';

const _template = 'assets/store_assets/source/paper_template_1080x1920.png';
const _paperArt = 'assets/store_assets/source/paper_art_3840x2143.png';
const _appIcon = 'assets/images/app_icon_new.png';

// 背景模板 (1080×1920) 裡已經畫了一支手機，新的外框要完整蓋住它：
// 綠幕在 x 258–813、y 435–1689，外框約再往外 35。以下座標都是模板座標。
const _templateSize = Size(1080, 1920);
const _templatePhoneCenterX = 535.5;

/// 圖檔一律同步讀進記憶體：Image.file 的讀檔會卡在測試的假時鐘裡，永遠等不到
final _byteCache = <String, Uint8List>{};
Uint8List _bytes(String path) =>
    _byteCache.putIfAbsent(path, () => File(path).readAsBytesSync());

const _ink = Color(0xFF4A3220);
const _inkSoft = Color(0xFF7A5634);

enum FrameKind { iphone, android, ipad }

/// 宣傳圖尺寸與裡面那台裝置
class PosterDevice {
  const PosterDevice(this.name, this.canvas, this.screen, this.kind,
      {required this.frameWidth, required this.frameTop});
  final String name;
  final Size canvas; // 輸出像素
  final Size screen; // 外框裡 App 的邏輯尺寸
  final FrameKind kind;
  final double frameWidth; // 模板座標
  final double frameTop; // 模板座標
}

const posterDevices = [
  PosterDevice('iphone_6.9', Size(1320, 2868), Size(440, 956), FrameKind.iphone,
      frameWidth: 670, frameTop: 372),
  // App Store 的 6.1 / 6.3 吋欄位只收 1206×2622 或 1179×2556，不收 6.9 吋的圖
  PosterDevice('iphone_6.3', Size(1206, 2622), Size(402, 874), FrameKind.iphone,
      frameWidth: 670, frameTop: 372),
  PosterDevice(
      'android_phone', Size(1080, 1920), Size(412, 892), FrameKind.android,
      frameWidth: 670, frameTop: 372),
  // iPad 比例較寬，放大到下緣超出畫面，才蓋得住模板裡的手機
  PosterDevice('ipad_13', Size(2064, 2752), Size(1032, 1376), FrameKind.ipad,
      frameWidth: 820, frameTop: 368),
];

/// 每張宣傳圖的標題 / 副標 (繁中、簡中、英文)
const _captions = <String, Map<String, (String, String)>>{
  '01_manual': {
    'zh_Hant': ('設定目標點擊計數', '念一聲、拜一拜，點一下'),
    'zh_Hans': ('设定目标点击计数', '念一声、拜一拜，点一下'),
    'en': ('Tap to Count', 'One tap for every recitation or bow'),
  },
  '02_auto': {
    'zh_Hant': ('跟著佛曲自動計數', '每念完一句佛號自動加一'),
    'zh_Hans': ('跟着佛曲自动计数', '每念完一句佛号自动加一'),
    'en': ('Counts Along with the Chant', '+1 for every line of the chant'),
  },
  '03_songs': {
    'zh_Hant': ('31 首佛曲', '彌陀、觀音、地藏聖號與六字大明咒'),
    'zh_Hans': ('31 首佛曲', '弥陀、观音、地藏圣号与六字大明咒'),
    'en': (
      '31 Buddhist Chants',
      'Amitabha, Avalokiteshvara, Ksitigarbha and more'
    ),
  },
  '04_dedication': {
    'zh_Hant': ('念佛迴向', '大回向文與回向偈'),
    'zh_Hans': ('念佛回向', '大回向文与回向偈'),
    'en': ('Dedication of Merit', 'Dedication verses after your practice'),
  },
  '05_calendar': {
    'zh_Hant': ('功課月曆', '每天的聲數與連續精進天數'),
    'zh_Hans': ('功课月历', '每天的声数与连续精进天数'),
    'en': ('Practice Calendar', 'Daily recitations and your streak'),
  },
  '06_classic': {
    'zh_Hant': ('經典介面', '沿用最早的版面，長輩一看就會'),
    'zh_Hans': ('经典界面', '沿用最早的版面，长辈一看就会'),
    'en': ('Classic Mode', 'The original layout, easy for everyone'),
  },
  '07_manual_dark': {
    'zh_Hant': ('深色模式', '夜裡念佛也不刺眼'),
    'zh_Hans': ('深色模式', '夜里念佛也不刺眼'),
    'en': ('Dark Mode', 'Easy on the eyes at night'),
  },
};

// ───────────────────────── 裝置外框 ─────────────────────────

class _FrameSpec {
  const _FrameSpec(this.bezel, this.radius, this.statusBar, this.homeBar);
  final double bezel; // 外框寬度比例
  final double radius; // 圓角比例
  final double statusBar; // 狀態列高度 (App 邏輯座標)
  final double homeBar; // 底部手勢列高度 (App 邏輯座標)
}

const _specs = {
  FrameKind.iphone: _FrameSpec(0.030, 0.150, 54, 34),
  FrameKind.android: _FrameSpec(0.028, 0.110, 36, 20),
  FrameKind.ipad: _FrameSpec(0.035, 0.060, 24, 20),
};

/// 外框的高度 (寬度為 [width] 時)
double frameHeight(double width, FrameKind kind, Size screen) {
  final b = width * _specs[kind]!.bezel;
  return (width - 2 * b) * screen.height / screen.width + 2 * b;
}

/// 香檳金外框 + 黑邊 + 螢幕；螢幕裡放 [child] (以 [screen] 的邏輯尺寸排版後縮放)
class DeviceFrame extends StatelessWidget {
  const DeviceFrame({
    super.key,
    required this.kind,
    required this.screen,
    required this.dark,
    required this.child,
  });

  final FrameKind kind;
  final Size screen;
  final bool dark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final spec = _specs[kind]!;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final outerR = w * spec.radius;
      final rim = w * 0.009;
      final b = w * spec.bezel;
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(outerR),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF6E9D9), Color(0xFFD9B994), Color(0xFFEFDCC4)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x663A2414),
              blurRadius: w * 0.07,
              offset: Offset(0, w * 0.035),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(rim),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF15110E),
              borderRadius: BorderRadius.circular(outerR - rim),
            ),
            child: Padding(
              padding: EdgeInsets.all(b - rim),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(outerR - b),
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: SizedBox.fromSize(
                    size: screen,
                    child: Stack(children: [
                      Positioned.fill(child: child),
                      _StatusBar(kind: kind, spec: spec, dark: dark),
                      _HomeBar(spec: spec, dark: dark),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar(
      {required this.kind, required this.spec, required this.dark});
  final FrameKind kind;
  final _FrameSpec spec;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = dark ? Colors.white : const Color(0xFF1C1917);
    final size = kind == FrameKind.ipad ? 13.0 : 16.0;
    final side = switch (kind) {
      FrameKind.iphone => 34.0,
      FrameKind.android => 22.0,
      FrameKind.ipad => 18.0,
    };
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: spec.statusBar,
      child: Stack(children: [
        // 動態島 / 前鏡頭
        if (kind == FrameKind.iphone)
          Align(
            alignment: const Alignment(0, -0.2),
            child: Container(
              width: 124,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        if (kind == FrameKind.android)
          const Align(
            child: CircleAvatar(radius: 6, backgroundColor: Colors.black),
          ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: side),
          child: Row(children: [
            Text('9:41',
                style: TextStyle(
                    color: color,
                    fontSize: size + 1,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto')),
            const Spacer(),
            Icon(Icons.signal_cellular_alt_rounded, size: size, color: color),
            const SizedBox(width: 4),
            Icon(Icons.wifi_rounded, size: size, color: color),
            const SizedBox(width: 4),
            Icon(Icons.battery_full_rounded, size: size + 2, color: color),
          ]),
        ),
      ]),
    );
  }
}

class _HomeBar extends StatelessWidget {
  const _HomeBar({required this.spec, required this.dark});
  final _FrameSpec spec;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: spec.homeBar,
      child: Center(
        child: Container(
          width: 134,
          height: 5,
          decoration: BoxDecoration(
            color: dark ? Colors.white70 : Colors.black87,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

/// 外框裡的真實 App：給它自己的螢幕尺寸與狀態列 / 手勢列留白
Widget liveApp(Widget app, FrameKind kind, Size screen) {
  final spec = _specs[kind]!;
  final insets = EdgeInsets.only(top: spec.statusBar, bottom: spec.homeBar);
  return MediaQuery(
    data: MediaQueryData(
      size: screen,
      devicePixelRatio: 3,
      padding: insets,
      viewPadding: insets,
    ),
    child: app,
  );
}

// ───────────────────────── 宣傳圖 ─────────────────────────

class _Poster extends StatelessWidget {
  const _Poster({
    required this.device,
    required this.title,
    required this.subtitle,
    required this.dark,
    required this.app,
  });

  final PosterDevice device;
  final String title;
  final String subtitle;
  final bool dark;
  final Widget app;

  @override
  Widget build(BuildContext context) {
    final canvas = device.canvas;
    // 模板以 cover 縮放、上緣對齊
    final s = [
      canvas.width / _templateSize.width,
      canvas.height / _templateSize.height,
    ].reduce((a, b) => a > b ? a : b);
    final ox = (canvas.width - _templateSize.width * s) / 2;
    final frameW = device.frameWidth * s;
    final frameH = frameHeight(frameW, device.kind, device.screen);
    final isLatin = !RegExp(r'[一-鿿]').hasMatch(title);

    Widget caption(
        String text, double centerY, double size, Color color, double spacing) {
      return Positioned(
        left: canvas.width * 0.08,
        right: canvas.width * 0.08,
        top: (centerY - size) * s,
        height: size * 2 * s,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              maxLines: 1,
              style: TextStyle(
                fontFamily: posterSerif,
                fontSize: size * s,
                height: 1.2,
                color: color,
                letterSpacing: size * s * spacing,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox.fromSize(
      size: canvas,
      child: Stack(children: [
        Positioned.fill(
          child: Image.memory(_bytes(_template),
              fit: BoxFit.cover, alignment: Alignment.topCenter),
        ),
        caption(title, 72, isLatin ? 52 : 58, _ink, isLatin ? 0.02 : 0.22),
        caption(subtitle, 254, isLatin ? 26 : 28, _inkSoft, 0.06),
        Positioned(
          left: ox + _templatePhoneCenterX * s - frameW / 2,
          top: device.frameTop * s,
          width: frameW,
          height: frameH,
          child: DeviceFrame(
            kind: device.kind,
            screen: device.screen,
            dark: dark,
            child: liveApp(app, device.kind, device.screen),
          ),
        ),
      ]),
    );
  }
}

const _posterShots = [
  '01_manual',
  '02_auto',
  '03_songs',
  '04_dedication',
  '05_calendar',
  '06_classic',
  '07_manual_dark',
];

/// README 橫幅用的四張 (Android 宣傳圖並排)
const _bannerShots = ['01_manual', '02_auto', '03_songs', '05_calendar'];

void registerPosterTests(ShotLocale l) {
  for (final d in posterDevices) {
    for (final name in _posterShots) {
      final s = shots.firstWhere((s) => s.name == name);
      testWidgets('poster ${d.name} ${l.name} $name', (tester) async {
        tester.view.physicalSize = d.canvas;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final app = await demoApp(l, s);
        final (title, subtitle) = _captions[name]![l.name]!;
        const key = ValueKey('poster');
        await tester.pumpWidget(RepaintBoundary(
          key: key,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: _Poster(
              device: d,
              title: title,
              subtitle: subtitle,
              // 經典模式的藍色標題列延伸到狀態列底下，狀態列文字要用白色
              dark: s.dark || s.legacy,
              app: app.provide(child: const BuddhaCounterApp()),
            ),
          ),
        ));
        await openShot(tester, l, s);
        await capture(
            tester, key, '$outDir/posters/${d.name}/${l.name}/$name.jpg', 1);
        await disposeAndSettleTimers(tester);
      });
    }
  }

  if (l.name != 'zh_Hant') return;

  testWidgets('README banner ${l.name}', (tester) async {
    const poster = Size(1080, 1920);
    tester.view.physicalSize = Size(poster.width * _bannerShots.length, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const key = ValueKey('banner');
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: Row(textDirection: TextDirection.ltr, children: [
        for (final name in _bannerShots)
          Image.memory(
            _bytes('$outDir/posters/android_phone/${l.name}/$name.jpg'),
            width: poster.width,
            height: poster.height,
          ),
      ]),
    ));
    await openShot(tester, l, const Shot('banner'));
    // 4320×1920 縮成一半，README 用剛好
    await capture(tester, key, '$outDir/posters/readme_banner.png', 0.5);
  });

  testWidgets('GitHub social preview ${l.name}', (tester) async {
    const canvas = Size(1280, 640);
    tester.view.physicalSize = canvas;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final app = await demoApp(l, shots.first);
    const screen = Size(440, 956);
    const phoneW = 250.0;
    final phoneH = frameHeight(phoneW, FrameKind.iphone, screen);
    Widget phone(double left, double top, Key key) => Positioned(
          left: left,
          top: top,
          width: phoneW,
          height: phoneH,
          child: DeviceFrame(
            key: key,
            kind: FrameKind.iphone,
            screen: screen,
            dark: false,
            child: liveApp(app.provide(child: const BuddhaCounterApp()),
                FrameKind.iphone, screen),
          ),
        );

    const key = ValueKey('social');
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.fromSize(
          size: canvas,
          child: Stack(children: [
            Positioned.fill(
                child: Image.memory(_bytes(_paperArt), fit: BoxFit.cover)),
            // 文字底下鋪一層淡淡的紙色，讓標題在紋路上也看得清楚
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    const Color(0xFFFAF3EA).withValues(alpha: 0.92),
                    const Color(0xFFFAF3EA).withValues(alpha: 0.75),
                    const Color(0xFFFAF3EA).withValues(alpha: 0.0),
                  ], stops: const [
                    0,
                    0.5,
                    0.75
                  ]),
                ),
              ),
            ),
            Positioned(
              left: 80,
              top: 0,
              bottom: 0,
              width: 560,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child:
                        Image.memory(_bytes(_appIcon), width: 120, height: 120),
                  ),
                  const SizedBox(height: 28),
                  const Text('念佛計數器', // i18n-ignore: 宣傳圖
                      style: TextStyle(
                          fontFamily: posterSerif,
                          fontSize: 76,
                          color: _ink,
                          letterSpacing: 8)),
                  const SizedBox(height: 12),
                  const Text('念佛、拜佛的隨身計數工具', // i18n-ignore: 宣傳圖
                      style: TextStyle(
                          fontFamily: posterSerif,
                          fontSize: 30,
                          color: _inkSoft,
                          letterSpacing: 2)),
                  const SizedBox(height: 22),
                  const Text(
                      'iPhone · iPad · Android · 網頁版', // i18n-ignore: 宣傳圖
                      style: TextStyle(
                          fontFamily: 'Roboto', fontSize: 22, color: _inkSoft)),
                ],
              ),
            ),
            phone(730, 60, const ValueKey('phoneA')),
            phone(990, 110, const ValueKey('phoneB')),
          ]),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    // 第二支手機切到功課月曆 (月初一樣改看上個月)
    Finder inPhoneB(Finder f) =>
        find.descendant(of: find.byKey(const ValueKey('phoneB')), matching: f);
    await tester.tap(inPhoneB(find.byType(NavigationDestination)).at(3));
    await tester.pumpAndSettle();
    if (DateTime.now().day < 15) {
      await tester.tap(inPhoneB(
          find.byTooltip(lookupAppLocalizations(l.locale).calendarPrevMonth)));
    }
    await openShot(tester, l, const Shot('social'));
    await capture(tester, key, '$outDir/posters/github_social_preview.png', 1);
    await disposeAndSettleTimers(tester);
  });
}
