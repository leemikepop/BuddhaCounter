import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/settings/settings_controller.dart';
import '../../l10n/l10n.dart';
import 'app_toast.dart';

/// AppBar 按鈕：鎖定 / 解除螢幕方向 (鎖定在目前的方向)
class OrientationLockButton extends StatelessWidget {
  const OrientationLockButton({super.key});

  @override
  Widget build(BuildContext context) {
    final locked =
        context.select<SettingsController, bool>((s) => s.isOrientationLocked);
    final l10n = context.l10n;
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: Icon(locked
          ? Icons.screen_lock_rotation_rounded
          : Icons.screen_rotation_rounded),
      tooltip:
          locked ? l10n.orientationUnlockTooltip : l10n.orientationLockTooltip,
      onPressed: () {
        context
            .read<SettingsController>()
            .toggleOrientationLock(MediaQuery.orientationOf(context));
        AppToast.show(
          context,
          locked ? l10n.orientationUnlockedToast : l10n.orientationLockedToast,
        );
      },
    );
  }
}

/// AppBar 按鈕：螢幕常亮 (防止休眠) 開關
class KeepScreenOnButton extends StatelessWidget {
  const KeepScreenOnButton({super.key});

  @override
  Widget build(BuildContext context) {
    final awake =
        context.select<SettingsController, bool>((s) => s.keepScreenOn);
    final l10n = context.l10n;
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: Icon(
          awake ? Icons.remove_red_eye_rounded : Icons.visibility_off_outlined),
      tooltip: awake ? l10n.screenAwakeOffTooltip : l10n.screenAwakeOn,
      onPressed: () {
        context.read<SettingsController>().toggleKeepScreenOn();
        AppToast.show(
          context,
          awake ? l10n.screenAwakeOffToast : l10n.screenAwakeOn,
        );
      },
    );
  }
}
