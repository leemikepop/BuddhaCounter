import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/chant_songs.dart';
import '../../../features/playback/playback_controller.dart';
import '../../../features/settings/settings_controller.dart';
import '../../common/swipeable_hui_xiang.dart';
import '../widgets/legacy_widgets.dart';

/// 經典模式迴向頁：進入時自動播放目前佛曲，離開時停止 (沿用最早 Android 版 MainActivity2)
class LegacyChantScreen extends StatefulWidget {
  const LegacyChantScreen({super.key});

  @override
  State<LegacyChantScreen> createState() => _LegacyChantScreenState();
}

class _LegacyChantScreenState extends State<LegacyChantScreen> {
  late final PlaybackController _playback;
  late final SettingsController _settings;

  @override
  void initState() {
    super.initState();
    _playback = context.read<PlaybackController>();
    _settings = context.read<SettingsController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _settings.applyWakelock();
      _playback.restartCurrent();
    });
  }

  @override
  void dispose() {
    _playback.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _playback.stop();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: legacyAppBar(context.l10n.legacyChantTitle),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 阿彌陀佛聖像
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Image.asset(
                    'assets/images/amitabha735x659.jpg',
                    height: 280,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/amitabha768x1024.png',
                      height: 280,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 可左右滑動切換之迴向文（大回向西方文 / 回向偈）
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SwipeableHuiXiangCarousel(
                    items: ChantConstants.huiXiangItems,
                    initialIndex: _settings.huiXiangIndex,
                    onIndexChanged: _settings.setHuiXiangIndex,
                    accentColor: LegacyColors.blue,
                    titleStyle: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    verseStyle: const TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    verseVerticalPadding: 3.0,
                    titleBottomSpacing: 8.0,
                    showLotusIcons: false,
                  ),
                ),

                const SizedBox(height: 12),

                // 南無阿彌陀佛
                Text(
                  context.l10n.practiceBuddhaName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: LegacyColors.blue,
                  ),
                ),

                const SizedBox(height: 20),

                // 返回按鈕
                LegacyPlainButton(
                  text: context.l10n.legacyBackHome,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  onPressed: () {
                    _playback.stop();
                    Navigator.pop(context);
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
