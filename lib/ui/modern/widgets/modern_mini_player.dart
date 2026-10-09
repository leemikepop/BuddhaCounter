import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/chant_songs.dart';
import '../../../features/counter/counter_view_model.dart';

/// 現代版常駐迷你音樂播放條 (Mini Music Player)
/// 浮動於各分頁底欄上方，提供快速切換、播放/暫停與展開播放器面板
class ModernMiniPlayer extends StatelessWidget {
  final VoidCallback onTapExpand;

  const ModernMiniPlayer({
    super.key,
    required this.onTapExpand,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();
    final song = ChantConstants.getSongById(vm.currentSongId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF20232B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF323642) : const Color(0xFFECE4D6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0xFF8C5E32).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTapExpand,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                // 梵音圖示 / 旋轉動態指示
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      vm.isChantPlaying
                          ? Icons.music_note_rounded
                          : Icons.music_off_outlined,
                      color: primary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 曲名與節奏
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '每拍 ${(song.beatIntervalMs / 1000).toStringAsFixed(2)}s · 點擊展開播放器',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFFA3A199)
                              : const Color(0xFF756F68),
                        ),
                      ),
                    ],
                  ),
                ),

                // 播控按鈕：播放/暫停
                IconButton(
                  icon: Icon(
                    vm.isChantPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: primary,
                    size: 34,
                  ),
                  tooltip: vm.isChantPlaying ? '暫停' : '播放',
                  onPressed: () {
                    vm.toggleChant(vm.currentSongId);
                  },
                ),

                // 播控按鈕：下一首
                IconButton(
                  icon: Icon(
                    Icons.skip_next_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    size: 26,
                  ),
                  tooltip: '下一首',
                  onPressed: () {
                    vm.playNextSong();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

