import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/chant_songs.dart';
import '../../../features/counter/counter_view_model.dart';
import '../../../l10n/chant_tag_labels.dart';
import '../../../l10n/l10n.dart';

/// 經典佛曲清單畫面 (忠實復刻原 MainActivity4 & activity_main_activity4.xml，並支援標籤分類篩選)
class LegacyMusicListScreen extends StatefulWidget {
  const LegacyMusicListScreen({super.key});

  @override
  State<LegacyMusicListScreen> createState() => _LegacyMusicListScreenState();
}

class _LegacyMusicListScreenState extends State<LegacyMusicListScreen> {
  ChantTag? _selectedTag; // null 代表「全部」

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<CounterViewModel>();
      vm.applyScreenWakelockForCurrentPage(vm.keepScreenSongs);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();
    final allSongs = ChantConstants.getAllSongs();
    final availableTags = ChantConstants.availableTags;
    final songs = _selectedTag == null
        ? allSongs
        : allSongs.where((s) => s.tags.contains(_selectedTag)).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('佛曲清單'),
        backgroundColor: const Color(0xFF0000FF),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 頂部標籤分類篩選列
            Container(
              color: const Color(0xFFF5F5F5),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('全部 (${allSongs.length})'),
                      selected: _selectedTag == null,
                      onSelected: (_) => setState(() => _selectedTag = null),
                      visualDensity: VisualDensity.compact,
                    ),
                    for (final tag in availableTags) ...[
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: Text(
                          '${chantTagLabel(context.l10n, tag)} (${ChantConstants.countSongsByTag(tag)})',
                        ),
                        selected: _selectedTag == tag,
                        onSelected: (val) {
                          setState(() {
                            _selectedTag =
                                (_selectedTag == tag && !val) ? null : tag;
                          });
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  final isCurrent = (vm.currentSongId == song.id);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCurrent
                              ? const Color(0xFFA1C9FF)
                              : const Color(0xFFF5F5F5),
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                          alignment: Alignment.centerLeft,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: BorderSide(
                              color: isCurrent
                                  ? const Color(0xFF0000FF)
                                  : const Color(0xFFBDBDBD),
                              width: isCurrent ? 2 : 1,
                            ),
                          ),
                        ),
                        onPressed: () {
                          vm.toggleChant(song.id);
                        },
                        child: Row(
                          children: [
                            Text(
                              '${song.id + 1}. ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCurrent
                                    ? const Color(0xFF0000FF)
                                    : Colors.black54,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                song.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isCurrent)
                              const Icon(
                                Icons.volume_up,
                                color: Color(0xFF0000FF),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 底部返回按鈕
            Container(
              padding: const EdgeInsets.all(8),
              color: const Color(0xFFEEEEEE),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE0E0E0),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '返回',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
