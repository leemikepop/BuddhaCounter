import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../features/playback/playback_controller.dart';
import '../../theme/modern_palette.dart';

/// 可拖曳的播放進度條與時間。拖曳期間通知播放器暫停回報進度 (避免自動計數誤算)，
/// 放開才跳轉；只有這個元件會隨播放進度重繪。
class PlayerProgressSlider extends StatefulWidget {
  const PlayerProgressSlider({super.key});

  @override
  State<PlayerProgressSlider> createState() => _PlayerProgressSliderState();
}

class _PlayerProgressSliderState extends State<PlayerProgressSlider> {
  /// 拖曳中的位置 (毫秒)；null 代表沒有在拖曳
  final ValueNotifier<double?> _dragMs = ValueNotifier(null);

  @override
  void dispose() {
    _dragMs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playback = context.read<PlaybackController>();
    final timeStyle =
        TextStyle(fontSize: 11, color: ModernPalette.of(context).mutedText);

    return ListenableBuilder(
      listenable: Listenable.merge([
        playback.positionListenable,
        playback.durationListenable,
        _dragMs,
      ]),
      builder: (context, _) {
        final duration = playback.duration;
        final maxMs = duration.inMilliseconds > 0
            ? duration.inMilliseconds.toDouble()
            : 1000.0;
        final dragMs = _dragMs.value;
        final shownMs = (dragMs ?? playback.position.inMilliseconds.toDouble())
            .clamp(0.0, maxMs);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: shownMs,
                max: maxMs,
                onChangeStart: (v) {
                  _dragMs.value = v;
                  playback.beginScrubbing();
                },
                onChanged: (v) => _dragMs.value = v,
                onChangeEnd: (v) {
                  _dragMs.value = null;
                  playback.endScrubbing(Duration(milliseconds: v.toInt()));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatMinSec(Duration(milliseconds: shownMs.toInt())),
                    style: timeStyle,
                  ),
                  Text(formatMinSec(duration), style: timeStyle),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
