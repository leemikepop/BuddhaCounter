import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/store_links.dart';
import '../../core/platform/app_platform.dart';
import '../../l10n/l10n.dart';

/// 網頁版的外框 (放在 MaterialApp.builder，包住整個 Navigator)：
/// - 電腦的寬螢幕：App 維持手機寬度置中，兩側留底色。內部的 MediaQuery 也改成手機寬度，
///   所以各畫面依寬度排版的邏輯、對話框與底部面板都只在這個範圍內。
/// - 手機瀏覽器：頂端顯示可關閉的「建議下載 App」提示。
/// 原生 App 不使用 (直接回傳 [child])。
class WebFrame extends StatelessWidget {
  const WebFrame({super.key, required this.child});

  final Widget child;

  /// App 畫面在電腦上的寬度
  static const double phoneWidth = 480;

  @override
  Widget build(BuildContext context) {
    if (!AppPlatform.isWeb) return child;

    final content =
        AppPlatform.isMobileBrowser ? GetAppBanner(child: child) : child;

    final media = MediaQuery.of(context);
    if (media.size.width <= phoneWidth) return content;

    final theme = Theme.of(context);
    final backdrop = Color.alphaBlend(
      Colors.black
          .withValues(alpha: theme.brightness == Brightness.dark ? 0.35 : 0.06),
      theme.scaffoldBackgroundColor,
    );
    return ColoredBox(
      color: backdrop,
      child: Center(
        child: Container(
          width: phoneWidth,
          height: media.size.height,
          decoration: const BoxDecoration(
            boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 24)],
          ),
          clipBehavior: Clip.hardEdge,
          child: MediaQuery(
            data: media.copyWith(size: Size(phoneWidth, media.size.height)),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// 手機瀏覽器頂端的「建議下載 App」提示 (只顯示該手機系統的商店)，關閉後 [child] 佔滿畫面
class GetAppBanner extends StatefulWidget {
  const GetAppBanner({super.key, required this.child});

  final Widget child;

  @override
  State<GetAppBanner> createState() => _GetAppBannerState();
}

class _GetAppBannerState extends State<GetAppBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return widget.child;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final store = isIOS ? 'App Store' : 'Google Play';
    final url = isIOS ? StoreLinks.appStore : StoreLinks.googlePlay;

    // 這裡在 Navigator 之外 (沒有 Overlay)，所以按鈕不用 tooltip
    final banner = Material(
      color: theme.colorScheme.primaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 4, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.webMobileBanner,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication),
                child: Text(store),
              ),
              Semantics(
                button: true,
                label: l10n.webBannerClose,
                child: InkResponse(
                  onTap: () => setState(() => _dismissed = true),
                  radius: 20,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.close_rounded, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Column(
      children: [
        banner,
        // 狀態列的高度已經由提示列的 SafeArea 處理
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
