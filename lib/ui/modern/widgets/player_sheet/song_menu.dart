import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/chant_songs.dart';
import '../../../../features/playback/playback_controller.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/song_tag_filter_bar.dart';
import '../../theme/modern_palette.dart';
import '../song_list_tile.dart';

/// 佛曲選單頂部 (吸附在面板上緣)：搜尋框、收合鈕、標籤篩選列
class SongMenuHeader extends StatelessWidget {
  const SongMenuHeader({
    super.key,
    required this.searchController,
    required this.keyword,
    required this.onKeywordChanged,
    required this.selectedTag,
    required this.onTagChanged,
    required this.showCollapseButton,
    required this.onCollapse,
    required this.onInteract,
  });

  final TextEditingController searchController;
  final String keyword;
  final ValueChanged<String> onKeywordChanged;
  final ChantTag? selectedTag;
  final ValueChanged<ChantTag?> onTagChanged;
  final bool showCollapseButton;
  final VoidCallback onCollapse;

  /// 點搜尋框、打字或選標籤時呼叫 (面板會自動展開)
  final VoidCallback onInteract;

  @override
  Widget build(BuildContext context) {
    final palette = ModernPalette.of(context);
    final l10n = context.l10n;

    return ColoredBox(
      color: palette.sheetBackground,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onTap: onInteract,
                    onChanged: (v) {
                      onInteract();
                      onKeywordChanged(v);
                    },
                    decoration: InputDecoration(
                      hintText: l10n.songMenuSearchHint,
                      hintStyle:
                          TextStyle(fontSize: 13, color: palette.searchHint),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: keyword.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                searchController.clear();
                                onKeywordChanged('');
                              },
                            ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      filled: true,
                      fillColor: palette.searchFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                if (showCollapseButton) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: l10n.songMenuBackToPlayer,
                    style: IconButton.styleFrom(
                        backgroundColor: palette.searchFill),
                    icon: Icon(Icons.keyboard_arrow_down_rounded,
                        color: palette.primary),
                    onPressed: onCollapse,
                  ),
                ],
              ],
            ),
          ),
          SongTagFilterBar(
            selected: selectedTag,
            onChanged: (tag) {
              onInteract();
              onTagChanged(tag);
            },
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

/// 篩選後的佛曲清單 (sliver)；點曲目換播該首，點右側按鈕播放 / 暫停
class SongMenuList extends StatelessWidget {
  const SongMenuList({super.key, required this.songs});

  final List<ChantSong> songs;

  @override
  Widget build(BuildContext context) {
    final (currentSongId, isPlaying) =
        context.select<PlaybackController, (int, bool)>(
      (p) => (p.currentSongId, p.isPlaying),
    );
    final playback = context.read<PlaybackController>();

    if (songs.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Text(
              context.l10n.songMenuNoMatch,
              style: TextStyle(color: ModernPalette.of(context).mutedText),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.only(
        top: 4,
        bottom: MediaQuery.paddingOf(context).bottom + 20,
      ),
      sliver: SliverList.builder(
        itemCount: songs.length,
        itemBuilder: (_, i) {
          final song = songs[i];
          return SongListTile(
            song: song,
            isSelected: currentSongId == song.id,
            isPlaying: isPlaying,
            onTap: () => playback.selectAndPlaySong(song.id),
            onTogglePlay: () => playback.toggleChant(song.id),
          );
        },
      ),
    );
  }
}
