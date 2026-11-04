import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/chant_songs.dart';
import '../../../../features/playback/playback_controller.dart';
import '../../../../l10n/l10n.dart';
import '../../theme/modern_palette.dart';
import 'player_progress_slider.dart';

/// 播放器面板上半部：曲目資訊、進度條、播控按鈕，以及展開 / 收合佛曲選單的提示列
class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.isMenuExpanded,
    required this.onToggleMenu,
  });

  final bool isMenuExpanded;
  final VoidCallback onToggleMenu;

  @override
  Widget build(BuildContext context) {
    final (songId, isPlaying, loopOne) =
        context.select<PlaybackController, (int, bool, bool)>(
      (p) => (p.currentSongId, p.isPlaying, p.isLoopingOne),
    );
    final playback = context.read<PlaybackController>();
    final song = ChantConstants.getSongById(songId);
    final palette = ModernPalette.of(context);
    final primary = palette.primary;
    final l10n = context.l10n;
    final songCount = ChantConstants.allSongs.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border:
                  Border.all(color: primary.withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(Icons.spa_rounded, color: primary, size: 30),
          ),
          const SizedBox(height: 10),
          Text(
            '#${(song.id + 1).toString().padLeft(2, '0')} ${song.title}',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.playerArtistAlbumBeat(
                song.artist, song.album, song.beatSeconds),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: palette.mutedText),
          ),
          const SizedBox(height: 8),
          const PlayerProgressSlider(),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  loopOne ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                  color: loopOne
                      ? primary
                      : palette.onSurface.withValues(alpha: 0.4),
                ),
                tooltip: loopOne ? l10n.playerLoopOne : l10n.playerLoopList,
                onPressed: playback.toggleLoopMode,
              ),
              IconButton(
                icon: const Icon(Icons.replay_10_rounded),
                tooltip: l10n.playerRewind10,
                onPressed: () => playback.seekRelative(-10),
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded, size: 28),
                tooltip: l10n.playerPrevious,
                onPressed: playback.playPreviousSong,
              ),
              Container(
                width: 52,
                height: 52,
                decoration:
                    BoxDecoration(color: primary, shape: BoxShape.circle),
                child: IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: palette.isDark ? Colors.black : Colors.white,
                    size: 30,
                  ),
                  tooltip: isPlaying ? l10n.commonPause : l10n.commonPlay,
                  onPressed: () => playback.toggleChant(songId),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded, size: 28),
                tooltip: l10n.playerNext,
                onPressed: playback.playNextSong,
              ),
              IconButton(
                icon: const Icon(Icons.forward_10_rounded),
                tooltip: l10n.playerForward10,
                onPressed: () => playback.seekRelative(10),
              ),
              IconButton(
                icon: Icon(
                  isMenuExpanded
                      ? Icons.expand_more_rounded
                      : Icons.playlist_play_rounded,
                  color: primary,
                ),
                tooltip: isMenuExpanded
                    ? l10n.songMenuCollapse
                    : l10n.songMenuExpand,
                onPressed: onToggleMenu,
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onToggleMenu,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: palette.isDark ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isMenuExpanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    size: 18,
                    color: primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isMenuExpanded
                        ? l10n.songMenuHeaderExpanded(songCount)
                        : l10n.songMenuHeaderCollapsed(songCount),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
