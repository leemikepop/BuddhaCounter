import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/chant_songs.dart';
import '../../../features/playback/playback_controller.dart';
import '../../../l10n/l10n.dart';
import '../../common/marquee_text.dart';
import '../theme/modern_palette.dart';
import 'player_sheet/player_sheet.dart';

/// 現代模式底部常駐的浮動播放條。點一下或往上滑會打開播放器面板，
/// 面板繼續往上拉就是佛曲選單 (見 [PlayerSheet])。
class ModernFloatingPlayer extends StatelessWidget {
  const ModernFloatingPlayer({super.key});

  /// 打開播放器面板並直接展開佛曲選單
  static void openSongPicker(BuildContext context) =>
      PlayerSheet.show(context, expanded: true);

  /// 打開播放器面板 (只顯示播放控制，可再往上拉出選單)
  static void openExpandedPlayer(BuildContext context) =>
      PlayerSheet.show(context, expanded: false);

  @override
  Widget build(BuildContext context) {
    final (songId, isPlaying) = context.select<PlaybackController, (int, bool)>(
      (p) => (p.currentSongId, p.isPlaying),
    );
    final playback = context.read<PlaybackController>();
    final current = ChantConstants.getSongById(songId);
    final palette = ModernPalette.of(context);
    final l10n = context.l10n;

    return RepaintBoundary(
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) < -180) {
            openExpandedPlayer(context);
          }
        },
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          decoration: BoxDecoration(
            color: palette.raisedCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.raisedCardBorder),
            boxShadow: [
              BoxShadow(
                color: palette.floatingShadow,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => openExpandedPlayer(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          _TrackNumberBadge(
                            number: current.id + 1,
                            highlighted: isPlaying,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MarqueeText(
                                  text: current.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: palette.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.playerArtistBeat(
                                    current.artist,
                                    current.beatSeconds,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 11, color: palette.mutedText),
                                ),
                              ],
                            ),
                          ),
                          _CompactIconButton(
                            icon: const Icon(Icons.skip_previous_rounded,
                                size: 22),
                            tooltip: l10n.playerPrevious,
                            minSize: 32,
                            onPressed: playback.playPreviousSong,
                          ),
                          _CompactIconButton(
                            icon: Icon(
                              isPlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_fill_rounded,
                              color: palette.primary,
                              size: 34,
                            ),
                            tooltip:
                                isPlaying ? l10n.commonPause : l10n.commonPlay,
                            minSize: 38,
                            onPressed: () => playback.toggleChant(songId),
                          ),
                          _CompactIconButton(
                            icon: const Icon(Icons.skip_next_rounded, size: 22),
                            tooltip: l10n.playerNext,
                            minSize: 32,
                            onPressed: playback.playNextSong,
                          ),
                          _CompactIconButton(
                            icon: Icon(Icons.playlist_play_rounded,
                                color: palette.primary, size: 26),
                            tooltip: l10n.songMenuExpand,
                            minSize: 34,
                            onPressed: () => openSongPicker(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 進度條獨立重繪，不會重建跑馬燈與按鈕列
                  RepaintBoundary(
                    child: ListenableBuilder(
                      listenable: Listenable.merge([
                        playback.positionListenable,
                        playback.durationListenable,
                      ]),
                      builder: (context, _) {
                        final totalMs = playback.duration.inMilliseconds;
                        final progress = totalMs > 0
                            ? (playback.position.inMilliseconds / totalMs)
                                .clamp(0.0, 1.0)
                            : 0.0;
                        return LinearProgressIndicator(
                          value: progress,
                          minHeight: 2.5,
                          backgroundColor: palette.progressTrack,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(palette.primary),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackNumberBadge extends StatelessWidget {
  const _TrackNumberBadge({required this.number, required this.highlighted});

  final int number;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final palette = ModernPalette.of(context);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: highlighted
            ? palette.primary.withValues(alpha: 0.18)
            : palette.badgeFill,
        shape: BoxShape.circle,
        border: Border.all(
          color: highlighted
              ? palette.primary.withValues(alpha: 0.6)
              : palette.badgeBorder,
          width: highlighted ? 1.5 : 1.0,
        ),
      ),
      child: Center(
        child: Text(
          number.toString().padLeft(2, '0'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: highlighted ? palette.primary : palette.mutedText,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

class _CompactIconButton extends StatelessWidget {
  const _CompactIconButton({
    required this.icon,
    required this.tooltip,
    required this.minSize,
    required this.onPressed,
  });

  final Widget icon;
  final String tooltip;
  final double minSize;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}
