import 'package:flutter/material.dart';
import '../../../core/constants/chant_songs.dart';
import '../../../l10n/chant_tag_labels.dart';
import '../../../l10n/l10n.dart';

/// 現代佛曲清單卡片組件（含分類標籤、平均節拍與演出者資訊）
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

  String _formatBeatSec(AppLocalizations l10n, int beatMs) {
    return l10n.songTileBeat((beatMs / 1000).toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final pillBg = isDark ? const Color(0xFF282B35) : const Color(0xFFEDE6DA);
    final pillFg = isDark ? const Color(0xFFAFAEA8) : const Color(0xFF6B655E);
    final tagBg = primary.withValues(alpha: isDark ? 0.16 : 0.10);

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
              : (isDark ? const Color(0xFF2C2F3B) : const Color(0xFFEDE6DA)),
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

                // 曲目資訊與標籤
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (isSelected && isPlaying) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.equalizer_rounded,
                              size: 15,
                              color: primary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (final tag in song.tags.take(3))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: tagBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                chantTagLabel(context.l10n, tag),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: primary,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: pillBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _formatBeatSec(
                                  context.l10n, song.effectiveBeatIntervalMs),
                              style: TextStyle(
                                fontSize: 10,
                                color: pillFg,
                              ),
                            ),
                          ),
                          Text(
                            song.artist,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFFA3A199)
                                  : const Color(0xFF756F68),
                            ),
                          ),
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
                  tooltip: (isSelected && isPlaying)
                      ? context.l10n.commonPause
                      : context.l10n.commonPlay,
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
