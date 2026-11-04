import 'package:flutter/material.dart';
import '../../core/constants/chant_songs.dart';
import '../../l10n/chant_tag_labels.dart';
import '../../l10n/l10n.dart';

/// 依標籤與關鍵字篩選曲目；關鍵字比對曲名、演出者、專輯與標籤名稱 (不分大小寫)
List<ChantSong> filterSongs(
  List<ChantSong> songs, {
  required AppLocalizations l10n,
  ChantTag? tag,
  String keyword = '',
}) {
  final kw = keyword.trim().toLowerCase();
  bool matches(String text) => text.toLowerCase().contains(kw);
  return songs.where((song) {
    if (tag != null && !song.tags.contains(tag)) return false;
    if (kw.isEmpty) return true;
    return matches(song.title) ||
        matches(song.artist) ||
        matches(song.album) ||
        song.tags.any((t) => matches(chantTagLabel(l10n, t)));
  }).toList();
}

/// 可橫向捲動的「全部 + 各標籤 (曲目數)」篩選列；再點一次已選的標籤會回到「全部」
class SongTagFilterBar extends StatelessWidget {
  const SongTagFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.spacing = 8,
  });

  /// 目前選取的標籤 (null = 全部)
  final ChantTag? selected;
  final ValueChanged<ChantTag?> onChanged;
  final EdgeInsetsGeometry padding;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget chip(String label, ChantTag? tag) => ChoiceChip(
          label: Text(label),
          selected: selected == tag,
          visualDensity: VisualDensity.compact,
          onSelected: (on) =>
              onChanged(tag != null && selected == tag && !on ? null : tag),
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          chip(l10n.songListAll(ChantConstants.allSongs.length), null),
          for (final tag in ChantConstants.availableTags) ...[
            SizedBox(width: spacing),
            chip(
              l10n.tagWithCount(
                chantTagLabel(l10n, tag),
                ChantConstants.countSongsByTag(tag),
              ),
              tag,
            ),
          ],
        ],
      ),
    );
  }
}
