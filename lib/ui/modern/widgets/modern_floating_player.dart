import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/chant_songs.dart';
import '../../../features/counter/counter_view_model.dart';
import 'song_list_tile.dart';

/// 現代禪意下方浮動音樂播放器 (Floating Bottom Music Player)
/// 具備：曲名顯示、節奏指示、上一首/播放暫停/下一首、選曲清單快捷展開、完整播控面板展開
class ModernFloatingPlayer extends StatelessWidget {
  const ModernFloatingPlayer({super.key});

  /// 彈出 31 首佛曲選取清單
  static void openSongPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _SongPickerBottomSheet(),
    );
  }

  /// 彈出完整播控面板 (進度條 Seek、快轉倒退、循環模式)
  static void openExpandedPlayer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ExpandedPlayerBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();
    final song = ChantConstants.getSongById(vm.currentSongId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final totalMs = vm.audioDuration.inMilliseconds;
    final curMs = vm.audioPosition.inMilliseconds;
    final progress = (totalMs > 0) ? (curMs / totalMs).clamp(0.0, 1.0) : 0.0;

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF20232B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF323644) : const Color(0xFFEBE3D5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : const Color(0xFF8C5E32).withValues(alpha: 0.1),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      // 曲目序號徽章 (取代原音樂圖標)
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: vm.isChantPlaying
                              ? primary.withValues(alpha: 0.18)
                              : (isDark
                                  ? const Color(0xFF2A2E3B)
                                  : const Color(0xFFF1EAE0)),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: vm.isChantPlaying
                                ? primary.withValues(alpha: 0.6)
                                : (isDark
                                    ? const Color(0xFF383C4D)
                                    : const Color(0xFFE2D8C8)),
                            width: vm.isChantPlaying ? 1.5 : 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            (song.id + 1).toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: vm.isChantPlaying
                                  ? primary
                                  : (isDark
                                      ? const Color(0xFFA3A199)
                                      : const Color(0xFF756F68)),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // 曲名與節奏
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MarqueeText(
                              text: song.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '每拍 ${(song.beatIntervalMs / 1000).toStringAsFixed(2)}s',
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

                      // 上一首
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: const Icon(Icons.skip_previous_rounded, size: 22),
                        tooltip: '上一首',
                        onPressed: () => vm.playPreviousSong(),
                      ),

                      // 播放/暫停主按鈕
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 38, minHeight: 38),
                        icon: Icon(
                          vm.isChantPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          color: primary,
                          size: 34,
                        ),
                        tooltip: vm.isChantPlaying ? '暫停' : '播放',
                        onPressed: () => vm.toggleChant(vm.currentSongId),
                      ),

                      // 下一首
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: const Icon(Icons.skip_next_rounded, size: 22),
                        tooltip: '下一首',
                        onPressed: () => vm.playNextSong(),
                      ),

                      // 選曲清單按鈕 (點擊直接選曲)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 34, minHeight: 34),
                        icon: Icon(
                          Icons.playlist_play_rounded,
                          color: primary,
                          size: 26,
                        ),
                        tooltip: '選曲清單 (31首)',
                        onPressed: () => openSongPicker(context),
                      ),
                    ],
                  ),
                ),
              ),
              // 微型即時進度條
              RepaintBoundary(
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 2.5,
                  backgroundColor:
                      isDark ? const Color(0xFF2E313D) : const Color(0xFFEDE4D5),
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

/// 佛曲選取清單 BottomSheet
class _SongPickerBottomSheet extends StatefulWidget {
  const _SongPickerBottomSheet();

  @override
  State<_SongPickerBottomSheet> createState() => _SongPickerBottomSheetState();
}

class _SongPickerBottomSheetState extends State<_SongPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';
  int _filterIndex = 0; // 0: 全部, 1: 快速, 2: 舒緩標準, 3: 莊嚴慢板

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChantSong> _getFilteredSongs() {
    return ChantConstants.allSongs.where((song) {
      if (_keyword.isNotEmpty &&
          !song.title.toLowerCase().contains(_keyword.toLowerCase())) {
        return false;
      }
      if (_filterIndex == 1 && song.beatIntervalMs > 1000) return false;
      if (_filterIndex == 2 &&
          (song.beatIntervalMs <= 1000 || song.beatIntervalMs >= 8000)) {
        return false;
      }
      if (_filterIndex == 3 && song.beatIntervalMs < 8000) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final filteredSongs = _getFilteredSongs();

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1D24) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // 頂部把手與標題
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3A3E4D) : const Color(0xFFDDD5C7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.library_music_rounded, color: primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  '選擇佛曲 (共 ${ChantConstants.allSongs.length} 首)',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // 搜尋輸入框
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜尋佛曲名稱...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF7E828E)
                      : const Color(0xFF9E9991),
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _keyword.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _keyword = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                filled: true,
                fillColor:
                    isDark ? const Color(0xFF242732) : const Color(0xFFF7F3EB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _keyword = val),
            ),
          ),

          // 篩選標籤
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildChip('全部 (${ChantConstants.allSongs.length})', 0),
                const SizedBox(width: 8),
                _buildChip('⚡ 快速', 1),
                const SizedBox(width: 8),
                _buildChip('🌿 舒緩標準', 2),
                const SizedBox(width: 8),
                _buildChip('🕊️ 莊嚴慢板', 3),
              ],
            ),
          ),
          const Divider(height: 1),

          // 清單
          Expanded(
            child: filteredSongs.isEmpty
                ? Center(
                    child: Text(
                      '無相符佛曲',
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
                    itemBuilder: (ctx, idx) {
                      final s = filteredSongs[idx];
                      final isSel = vm.currentSongId == s.id;
                      return SongListTile(
                        song: s,
                        isSelected: isSel,
                        isPlaying: vm.isChantPlaying,
                        onTap: () {
                          vm.selectAndPlaySong(s.id);
                        },
                        onTogglePlay: () {
                          vm.toggleChant(s.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, int index) {
    final isSel = _filterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      onSelected: (val) {
        if (val) setState(() => _filterIndex = index);
      },
      visualDensity: VisualDensity.compact,
    );
  }
}

/// 完整播控面板 BottomSheet
class _ExpandedPlayerBottomSheet extends StatelessWidget {
  const _ExpandedPlayerBottomSheet();

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();
    final song = ChantConstants.getSongById(vm.currentSongId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final position = vm.audioPosition;
    final duration = vm.audioDuration;
    final maxMs = (duration.inMilliseconds > 0)
        ? duration.inMilliseconds.toDouble()
        : 1000.0;
    final curMs = position.inMilliseconds.toDouble().clamp(0.0, maxMs);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1D24) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 把手
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF3A3E4D) : const Color(0xFFDDD5C7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 圓形光環唱片視覺
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border:
                    Border.all(color: primary.withValues(alpha: 0.3), width: 2),
              ),
              child: Center(
                child: Icon(Icons.spa_rounded, color: primary, size: 36),
              ),
            ),
            const SizedBox(height: 14),

            // 曲名
            Text(
              '#${(song.id + 1).toString().padLeft(2, '0')} ${song.title}',
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '節奏：每拍 ${(song.beatIntervalMs / 1000).toStringAsFixed(2)} 秒',
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark ? const Color(0xFFA3A199) : const Color(0xFF756F68),
              ),
            ),
            const SizedBox(height: 14),

            // 進度條
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

            // 時間
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
            const SizedBox(height: 10),

            // 播控按鈕：循環、上一首、倒退10s、播放/暫停、快轉10s、下一首、選曲
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 循環
                IconButton(
                  icon: Icon(
                    vm.releaseMode == ReleaseMode.loop
                        ? Icons.repeat_one_rounded
                        : Icons.repeat_rounded,
                    color: vm.releaseMode == ReleaseMode.loop
                        ? primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  tooltip: vm.releaseMode == ReleaseMode.loop ? '單曲循環' : '清單播放',
                  onPressed: () => vm.toggleAudioLoop(),
                ),
                // 倒退10s
                IconButton(
                  icon: const Icon(Icons.replay_10_rounded),
                  tooltip: '倒退 10 秒',
                  onPressed: () => vm.seekAudioRelative(-10),
                ),
                // 上一首
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, size: 28),
                  tooltip: '上一首',
                  onPressed: () => vm.playPreviousSong(),
                ),
                // 播放 / 暫停
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      vm.isChantPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: isDark ? Colors.black : Colors.white,
                      size: 32,
                    ),
                    onPressed: () => vm.toggleChant(vm.currentSongId),
                  ),
                ),
                // 下一首
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, size: 28),
                  tooltip: '下一首',
                  onPressed: () => vm.playNextSong(),
                ),
                // 快轉10s
                IconButton(
                  icon: const Icon(Icons.forward_10_rounded),
                  tooltip: '快轉 10 秒',
                  onPressed: () => vm.seekAudioRelative(10),
                ),
                // 選曲清單
                IconButton(
                  icon: Icon(Icons.playlist_play_rounded, color: primary),
                  tooltip: '選曲清單',
                  onPressed: () {
                    Navigator.pop(context);
                    ModernFloatingPlayer.openSongPicker(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// 自動滾動跑馬燈文字組件 (文字過長超出邊界時，自動左右循環平滑滑動)
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const MarqueeText({
    super.key,
    required this.text,
    this.style,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  late final ScrollController _scrollController;
  int _scrollCycleId = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndStartScroll());
  }

  @override
  void didUpdateWidget(covariant MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _scrollCycleId++;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndStartScroll());
    }
  }

  @override
  void dispose() {
    _scrollCycleId++;
    _scrollController.dispose();
    super.dispose();
  }

  void _checkAndStartScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent > 0) {
      _runScrollLoop(_scrollCycleId);
    }
  }

  Future<void> _runScrollLoop(int cycleId) async {
    while (mounted && _scrollCycleId == cycleId) {
      // 滾動前停留片刻以利閱讀開頭
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted || _scrollCycleId != cycleId || !_scrollController.hasClients) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent <= 0) return;

      // 依字長等比設定平滑滑動時間 (約 35-40px/秒)
      final durationMs = (maxExtent * 40).toInt().clamp(2000, 10000);
      try {
        await _scrollController.animateTo(
          maxExtent,
          duration: Duration(milliseconds: durationMs),
          curve: Curves.linear,
        );
      } catch (_) {
        return;
      }

      if (!mounted || _scrollCycleId != cycleId || !_scrollController.hasClients) return;
      // 抵達尾端停留片刻以利閱讀完整內容
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted || _scrollCycleId != cycleId || !_scrollController.hasClients) return;

      try {
        await _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      } catch (_) {
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        maxLines: 1,
        softWrap: false,
        style: widget.style,
      ),
    );
  }
}
