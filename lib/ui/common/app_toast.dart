import 'package:flutter/material.dart';

/// 統一的快顯通知元件 (Unified Toast / SnackBar Component)
class AppToast {
  AppToast._();

  /// 預設快顯時間：0.4 秒 (400ms)
  static const Duration defaultDuration = Duration(milliseconds: 400);

  /// 顯示短暫快顯通知
  static void show(
    BuildContext context,
    String message, {
    Duration duration = defaultDuration,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    IconData? icon,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Flexible(child: Text(message)),
                ],
              )
            : Text(message),
        duration: duration,
        behavior: behavior,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
