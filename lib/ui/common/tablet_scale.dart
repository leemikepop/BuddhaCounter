import 'package:flutter/widgets.dart';

import '../../core/platform/app_platform.dart';

/// 平板上把整個 App 等比放大：版面以「大手機」的寬度排，字、按鈕與點擊範圍一起變大。
///
/// 版面是照手機設計的 (固定大小的計數圈、按鈕)，在 iPad 上原尺寸只會佔畫面一小塊。
/// 放大倍率 = 最短邊 / [baseShortestSide]，最多 [maxScale] 倍；手機 (最短邊 < 600) 不受影響。
/// 網頁版不放大 (寬螢幕由 WebFrame 固定成手機寬度)。
class TabletScale extends StatelessWidget {
  const TabletScale({super.key, required this.child});

  final Widget child;

  static const double baseShortestSide = 600;
  static const double maxScale = 1.5;

  static double scaleFor(Size size) {
    if (AppPlatform.isWeb) return 1;
    return (size.shortestSide / baseShortestSide).clamp(1.0, maxScale);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final scale = scaleFor(mq.size);
    if (scale == 1) return child;

    final logical = mq.size / scale;
    return MediaQuery(
      data: mq.copyWith(
        size: logical,
        // 圖片依像素比挑解析度：放大後要用更高解析度的圖才不會糊
        devicePixelRatio: mq.devicePixelRatio * scale,
        padding: mq.padding / scale,
        viewPadding: mq.viewPadding / scale,
        viewInsets: mq.viewInsets / scale,
        systemGestureInsets: mq.systemGestureInsets / scale,
      ),
      // 以縮小後的尺寸排版，再整塊放大繪製 (點擊座標也會一起換算)
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topLeft,
        child: SizedBox.fromSize(size: logical, child: child),
      ),
    );
  }
}
