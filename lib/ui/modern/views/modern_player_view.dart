import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/chant_songs.dart';
import '../../../features/counter/counter_view_model.dart';
import '../widgets/song_list_tile.dart';

/// 現代禪意【佛曲梵音播放器】專屬視圖
/// 全功能音樂播放器：含進度條拖曳、上一首/下一首、快轉倒退、循環切換、31首完整曲庫與即時搜尋
class ModernPlayerView extends StatefulWidget {
  const ModernPlayerView({super.key});

  @override
  State<ModernPlayerView> createState() => _ModernPlayerViewState();
}

class _ModernPlayerViewState extends State<ModernPlayerView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';
  int _tempoFilterIndex = 0; // 0: 全部, 1: 快速, 2: 舒緩標準, 3: 莊嚴慢板

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  List<ChantSong> _getFilteredSongs() {
    return ChantConstants.allSongs.where((song) {
      if (_searchKeyword.isNotEmpty &&
          !song.title.toLowerCase().contains(_searchKeyword.toLowerCase())) {
        return false;
      }
      if (_tempoFilterIndex == 1 && song.beatIntervalMs > 1000) return false;
      if (_tempoFilterIndex == 2 &&
          (song.beatIntervalMs <= 1000 || song.beatIntervalMs >= 8000)) {
        return false;
      }
      if (_tempoFilterIndex == 3 && song.beatIntervalMs < 8000) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final currentSong = ChantConstants.getSongById(vm.currentSongId);
    final filteredSongs = _getFilteredSongs();

    final position = vm.audioPosition;
    final duration = vm.audioDuration;
    final maxMs = (duration.inMilliseconds > 0)
        ? duration.inMilliseconds.toDouble()
        : 1000.0;
    final curMs = position.inMilliseconds.toDouble().clamp(0.0, maxMs);

    return Column(
      children: [
        // 頂部核心播放卡片 (Now Playing Card)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2027) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF2E323E) : const Color(0xFFEFE8DC),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : primary.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // 佛曲標題與節奏說明
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.library_music_rounded,
                        color: primary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${(currentSong.id + 1).toString().padLeft(2, '0')} · ${currentSong.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '節奏頻率：每拍 ${(currentSong.beatIntervalMs / 1000).toStringAsFixed(2)} 秒',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFFA3A199)
                                : const Color(0xFF756F68),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 循環模式開關
                  IconButton(
                    icon: Icon(
                      vm.releaseMode == ReleaseMode.loop
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                      color: vm.releaseMode == ReleaseMode.loop
                          ? primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      size: 22,
                    ),
                    tooltip: vm.releaseMode == ReleaseMode.loop ? '單曲循環' : '清單播放',
                    onPressed: () => vm.toggleAudioLoop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 進度條 (Slider)
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                ),
                child: Slider(
                  value: curMs,
                  min: 0.0,
                  max: maxMs,
                  onChanged: (val) {
                    vm.seekAudio(Duration(milliseconds: val.toInt()));
                  },
                ),
              ),

              // 時間顯示
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(position),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFFA3A199)
                            : const Color(0xFF756F68),
                      ),
                    ),
                    Text(
                      _formatDuration(duration),
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
              const SizedBox(height: 8),

              // 播控按鈕列：上一首、倒退10秒、播放/暫停、快轉10秒、下一首
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 上一首
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, size: 28),
                    tooltip: '上一首',
                    onPressed: () => vm.playPreviousSong(),
                  ),

                  // 倒退 10 秒
                  IconButton(
                    icon: const Icon(Icons.replay_10_rounded, size: 24),
                    tooltip: '倒退 10 秒',
                    onPressed: () => vm.seekAudioRelative(-10),
                  ),

                  // 播放 / 暫停主按鈕
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        vm.isChantPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: isDark ? Colors.black : Colors.white,
                        size: 34,
                      ),
                      tooltip: vm.isChantPlaying ? '暫停' : '播放',
                      onPressed: () => vm.toggleChant(vm.currentSongId),
                    ),
                  ),

                  // 快轉 10 秒
                  IconButton(
                    icon: const Icon(Icons.forward_10_rounded, size: 24),
                    tooltip: '快轉 10 秒',
                    onPressed: () => vm.seekAudioRelative(10),
                  ),

                  // 下一首
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, size: 28),
                    tooltip: '下一首',
                    onPressed: () => vm.playNextSong(),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 搜尋列與篩選標籤
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜尋 31 首佛曲名稱...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFF7E828E)
                    : const Color(0xFF9E9991),
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchKeyword.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchKeyword = '';
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E2027) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF2E323E)
                      : const Color(0xFFEFE8DC),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF2E323E)
                      : const Color(0xFFEFE8DC),
                ),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _searchKeyword = val;
              });
            },
          ),
        ),
        const SizedBox(height: 8),

        // 篩選標籤 Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildFilterChip('全部 (${ChantConstants.allSongs.length})', 0),
              const SizedBox(width: 8),
              _buildFilterChip('⚡ 快速', 1),
              const SizedBox(width: 8),
              _buildFilterChip('🌿 舒緩標準', 2),
              const SizedBox(width: 8),
              _buildFilterChip('🕊️ 莊嚴慢板', 3),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // 31 首佛曲清單列表
        Expanded(
          child: filteredSongs.isEmpty
              ? Center(
                  child: Text(
                    '無相符的佛曲',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFA3A199)
                          : const Color(0xFF756F68),
                    ),
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredSongs.length,
                  itemBuilder: (context, index) {
                    final song = filteredSongs[index];
                    final isSel = vm.currentSongId == song.id;
                    return SongListTile(
                      song: song,
                      isSelected: isSel,
                      isPlaying: vm.isChantPlaying,
                      onTap: () {
                        vm.selectAndPlaySong(song.id);
                      },
                      onTogglePlay: () {
                        vm.toggleChant(song.id);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSel = _tempoFilterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      onSelected: (val) {
        if (val) {
          setState(() {
            _tempoFilterIndex = index;
          });
        }
      },
      visualDensity: VisualDensity.compact,
    );
  }
}
