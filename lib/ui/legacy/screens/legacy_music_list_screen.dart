import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/chant_songs.dart';
import '../../../features/playback/playback_controller.dart';
import '../../../features/settings/settings_controller.dart';
import '../../../l10n/l10n.dart';
import '../../common/song_tag_filter_bar.dart';
import '../widgets/legacy_widgets.dart';

/// 經典模式佛曲清單 (沿用最早 Android 版 MainActivity4，加上標籤篩選)。點曲目播放 / 暫停。
class LegacyMusicListScreen extends StatefulWidget {
  const LegacyMusicListScreen({super.key});

  @override
  State<LegacyMusicListScreen> createState() => _LegacyMusicListScreenState();
}

class _LegacyMusicListScreenState extends State<LegacyMusicListScreen> {
  ChantTag? _selectedTag; // null = 全部

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SettingsController>().applyWakelock();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentSongId =
        context.select<PlaybackController, int>((p) => p.currentSongId);
    final playback = context.read<PlaybackController>();
    final songs = filterSongs(
      ChantConstants.allSongs,
      l10n: context.l10n,
      tag: _selectedTag,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: legacyAppBar(context.l10n.legacySongListTitle),
      body: SafeArea(
        child: Column(
          children: [
            ColoredBox(
              color: const Color(0xFFF5F5F5),
              child: SongTagFilterBar(
                selected: _selectedTag,
                onChanged: (tag) => setState(() => _selectedTag = tag),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                spacing: 6,
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
                  final isCurrent = currentSongId == song.id;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCurrent
                              ? LegacyColors.lightBlue
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
                                  ? LegacyColors.blue
                                  : const Color(0xFFBDBDBD),
                              width: isCurrent ? 2 : 1,
                            ),
                          ),
                        ),
                        onPressed: () => playback.toggleChant(song.id),
                        child: Row(
                          children: [
                            Text(
                              '${song.id + 1}. ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCurrent
                                    ? LegacyColors.blue
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
                child: LegacyPlainButton(
                  text: context.l10n.commonBack,
                  fontSize: 18,
                  bold: true,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
