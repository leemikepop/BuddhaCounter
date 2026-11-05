import 'package:flutter/foundation.dart';

/// 執行環境與功能支援的判斷集中在這裡。
///
/// 注意：在 Web 上 [defaultTargetPlatform] 是「瀏覽器所在的作業系統」，
/// 用 iPhone 的 Safari 開網頁時它也是 iOS。要判斷「原生 iOS App」一律用 [isNativeIOS]。
abstract final class AppPlatform {
  /// 測試用：模擬在 Web 上執行 ([kIsWeb] 是編譯期常數，無法在 VM 測試中改變)
  @visibleForTesting
  static bool? debugIsWebOverride;

  static bool get isWeb => debugIsWebOverride ?? kIsWeb;

  static bool get isNativeIOS =>
      !isWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isNativeAndroid =>
      !isWeb && defaultTargetPlatform == TargetPlatform.android;

  /// 用手機瀏覽器開網頁版 (會建議改下載 App)
  static bool get isMobileBrowser =>
      isWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  /// 桌面小工具 (Web 沒有)
  static bool get supportsHomeWidget => !isWeb;

  /// 每日定時提醒 (Web 不支援本機排程通知)
  static bool get supportsReminders => !isWeb;

  /// 鎖定螢幕方向 (瀏覽器不支援)
  static bool get supportsOrientationLock => !isWeb;
}
