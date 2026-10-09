import 'package:flutter/material.dart';
import '../../../core/constants/chant_songs.dart';

/// 現代佛曲清單卡片組件
class SongListTile extends StatelessWidget {
  final ChantSong song;
  final bool isSelected;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onTogglePlay;

  const SongListTile({
    super.key,
    required this.song,
    required this.isSelected,
    required this.isPlaying,
    required this.onTap,
    required this.onTogglePlay,
  });

  String _getTempoBadge(int beatMs) {
    final sec = (beatMs / 1000).toStringAsFixed(2);
    if (beatMs <= 1000) {
      return '⚡ 快速 ($sec s/拍)';
    } else if (beatMs >= 8000) {
      return '🕊️ 莊嚴慢板 ($sec s/拍)';
    } else {
      return '🌿 舒緩標準 ($sec s/拍)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark
                ? primary.withValues(alpha: 0.15)
                : primary.withValues(alpha: 0.08))
            : (isDark ? const Color(0xFF1F2128) : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? primary
              : (isDark
                  ? const Color(0xFF2C2F3B)
                  : const Color(0xFFEDE6DA)),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // 序號方塊
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primary
                        : (isDark
                            ? const Color(0xFF282B35)
                            : const Color(0xFFF3EDE3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${song.id + 1}'.padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? const Color(0xFFB5B3AA)
                                : const Color(0xFF756F68)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 曲目資訊
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
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF282B35)
                                  : const Color(0xFFEDE6DA),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getTempoBadge(song.beatIntervalMs),
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? const Color(0xFFAFAEA8)
                                    : const Color(0xFF6B655E),
                              ),
                            ),
                          ),
                          if (isSelected && isPlaying) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.equalizer_rounded,
                              size: 14,
                              color: primary,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // 播放按鈕
                IconButton(
                  icon: Icon(
                    (isSelected && isPlaying)
                        ? Icons.pause_circle_rounded
                        : Icons.play_circle_outline_rounded,
                    color: isSelected
                        ? primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 28,
                  ),
                  tooltip: (isSelected && isPlaying) ? '暫停' : '播放',
                  onPressed: onTogglePlay,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

