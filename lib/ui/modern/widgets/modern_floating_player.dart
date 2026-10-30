import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/chant_songs.dart';
import '../../../features/counter/counter_view_model.dart';
import 'song_list_tile.dart';

/// 現代禪意下方浮動音樂播放器 (Floating Bottom Music Player)
/// 點擊或上滑可彈出整合式可上滑面板（下半部為音樂播控，繼續上滑即無縫展開標籤分類佛曲選單）
class ModernFloatingPlayer extends StatelessWidget {
  const ModernFloatingPlayer({super.key});

  /// 直接以展開佛曲選單狀態開啟整合式播放器面板
  static void openSongPicker(BuildContext context) {
    _openUnifiedSheet(context, initialExpanded: true);
  }

  /// 以精簡下半部播控狀態開啟整合式播放器面板（可繼續向上滑動展開佛曲選單）
  static void openExpandedPlayer(BuildContext context) {
    _openUnifiedSheet(context, initialExpanded: false);
  }

  static void _openUnifiedSheet(
    BuildContext context, {
    required bool initialExpanded,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UnifiedPlayerBottomSheet(
        initialExpanded: initialExpanded,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (currentSongId, isChantPlaying) =
        context.select<CounterViewModel, (int, bool)>(
      (vm) => (vm.currentSongId, vm.isChantPlaying),
    );
    final vm = context.read<CounterViewModel>();
    final song = ChantConstants.getSongById(currentSongId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          // 曲目序號徽章
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isChantPlaying
                                  ? primary.withValues(alpha: 0.18)
                                  : (isDark
                                      ? const Color(0xFF2A2E3B)
                                      : const Color(0xFFF1EAE0)),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isChantPlaying
                                    ? primary.withValues(alpha: 0.6)
                                    : (isDark
                                        ? const Color(0xFF383C4D)
                                        : const Color(0xFFE2D8C8)),
                                width: isChantPlaying ? 1.5 : 1.0,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                (song.id + 1).toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isChantPlaying
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

                          // 曲名與演出者/節奏
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
                                  '${song.artist} · 每拍 ${(song.effectiveBeatIntervalMs / 1000).toStringAsFixed(2)}s',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            icon: const Icon(
                              Icons.skip_previous_rounded,
                              size: 22,
                            ),
                            tooltip: '上一首',
                            onPressed: () => vm.playPreviousSong(),
                          ),

                          // 播放/暫停主按鈕
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 38,
                              minHeight: 38,
                            ),
                            icon: Icon(
                              isChantPlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_fill_rounded,
                              color: primary,
                              size: 34,
                            ),
                            tooltip: isChantPlaying ? '暫停' : '播放',
                            onPressed: () => vm.toggleChant(currentSongId),
                          ),

                          // 下一首
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            icon: const Icon(Icons.skip_next_rounded, size: 22),
                            tooltip: '下一首',
                            onPressed: () => vm.playNextSong(),
                          ),

                          // 選曲清單快捷按鈕
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 34,
                              minHeight: 34,
                            ),
                            icon: Icon(
                              Icons.playlist_play_rounded,
                              color: primary,
                              size: 26,
                            ),
                            tooltip: '展開佛曲選單',
                            onPressed: () => openSongPicker(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 微型即時進度條（獨立局部重繪，不觸發外層跑馬燈與按鈕列重建）
                  RepaintBoundary(
                    child: ListenableBuilder(
                      listenable: Listenable.merge([
                        vm.audioPositionListenable,
                        vm.audioDurationListenable,
                      ]),
                      builder: (context, _) {
                        final totalMs =
                            vm.audioDurationListenable.value.inMilliseconds;
                        final curMs =
                            vm.audioPositionListenable.value.inMilliseconds;
                        final progress = (totalMs > 0)
                            ? (curMs / totalMs).clamp(0.0, 1.0)
                            : 0.0;
                        return LinearProgressIndicator(
                          value: progress,
                          minHeight: 2.5,
                          backgroundColor: isDark
                              ? const Color(0xFF2E313D)
                              : const Color(0xFFEDE4D5),
                          valueColor: AlwaysStoppedAnimation<Color>(primary),
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

/// 整合式可上滑音樂播放器與標籤分類佛曲選單 (Unified Draggable Player & Song Menu Sheet)
/// - 初始下半部高度：呈現完整音樂播控卡片
/// - 繼續向上滑動：無縫展開搜尋欄、分類標籤篩選列與 31 首佛曲選單
class _UnifiedPlayerBottomSheet extends StatefulWidget {
  final bool initialExpanded;

  const _UnifiedPlayerBottomSheet({
    required this.initialExpanded,
  });

  @override
  State<_UnifiedPlayerBottomSheet> createState() =>
      _UnifiedPlayerBottomSheetState();
}

class _UnifiedPlayerBottomSheetState extends State<_UnifiedPlayerBottomSheet> {
  static const double _grabberHeight = 22.0;
  static const double _defaultPlayerContentHeight = 276.0;
  static const double _expandedSize = 0.94;

  final GlobalKey _playerContentKey = GlobalKey();
  double? _measuredContentHeight;
  bool _measureScheduled = false;
  bool _isAnimatingSheet = false;
  double _currentCollapsedSize = 0.38;
  late final DraggableScrollableController _sheetController;
  final TextEditingController _searchController = TextEditingController();
  ScrollController? _activeScrollController;

  String _keyword = '';
  String? _selectedTag; // null 代表「全部」
  final ValueNotifier<double?> _dragValueNotifier = ValueNotifier<double?>(null);
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
    _sheetController = DraggableScrollableController();
    _sheetController.addListener(_onSheetSizeChanged);
  }

  void _onSheetSizeChanged() {
    if (!_sheetController.isAttached) return;
    final midpoint = (_currentCollapsedSize + _expandedSize) / 2.0;
    final nowExpanded = _sheetController.size >= midpoint;
    if (nowExpanded != _isExpanded && mounted) {
      setState(() {
        _isExpanded = nowExpanded;
      });
    }
  }

  void _scheduleMeasurePlayerHeight(
    double availHeight,
    double bottomClearance,
  ) {
    if (_measureScheduled) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      if (!mounted) return;
      final box = _playerContentKey.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      final contentH = box.size.height;
      if (_measuredContentHeight == null ||
          (contentH - _measuredContentHeight!).abs() > 0.5) {
        final oldCollapsed = _currentCollapsedSize;
        final newTotalPx = _grabberHeight + contentH + bottomClearance;
        final newCollapsed =
            (newTotalPx / math.max(availHeight, 360.0)).clamp(0.24, 0.82);
        setState(() {
          _measuredContentHeight = contentH;
          _currentCollapsedSize = newCollapsed;
        });
        if (!_isExpanded &&
            !_isAnimatingSheet &&
            _sheetController.isAttached &&
            (_sheetController.size - oldCollapsed).abs() < 0.05) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                !_isExpanded &&
                !_isAnimatingSheet &&
                _sheetController.isAttached) {
              _sheetController.jumpTo(_currentCollapsedSize);
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetSizeChanged);
    _sheetController.dispose();
    _searchController.dispose();
    _dragValueNotifier.dispose();
    super.dispose();
  }

  Future<void> _expandSheetIfNeeded() async {
    if (!_sheetController.isAttached) return;
    if (_sheetController.size < _expandedSize - 0.03) {
      _isAnimatingSheet = true;
      try {
        await _sheetController.animateTo(
          _expandedSize,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      } catch (_) {
      } finally {
        _isAnimatingSheet = false;
      }
    }
  }

  Future<void> _toggleSheetExpansion() async {
    if (!_sheetController.isAttached) return;
    if (_isExpanded) {
      if (_activeScrollController != null &&
          _activeScrollController!.hasClients &&
          _activeScrollController!.offset > 0) {
        _activeScrollController!.jumpTo(0);
      }
      _isAnimatingSheet = true;
      try {
        await _sheetController.animateTo(
          _currentCollapsedSize,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      } catch (_) {
      } finally {
        _isAnimatingSheet = false;
      }
    } else {
      await _expandSheetIfNeeded();
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  List<ChantSong> _getFilteredSongs() {
    final kw = _keyword.trim().toLowerCase();
    return ChantConstants.allSongs.where((song) {
      if (_selectedTag != null && !song.tags.contains(_selectedTag)) {
        return false;
      }
      if (kw.isNotEmpty &&
          !song.title.toLowerCase().contains(kw) &&
          !song.artist.toLowerCase().contains(kw) &&
          !song.album.toLowerCase().contains(kw) &&
          !song.tags.any((t) => t.toLowerCase().contains(kw))) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final (currentSongId, isChantPlaying, releaseMode) =
        context.select<CounterViewModel, (int, bool, ReleaseMode)>(
      (vm) => (vm.currentSongId, vm.isChantPlaying, vm.releaseMode),
    );
    final vm = context.read<CounterViewModel>();
    final song = ChantConstants.getSongById(currentSongId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final sheetBg = isDark ? const Color(0xFF1B1D24) : Colors.white;

    final availableTags = ChantConstants.availableTags;
    final filteredSongs = _getFilteredSongs();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final bottomClearance = math.max(14.0, bottomSafe + 8.0);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availHeight = constraints.maxHeight;
          final contentH =
              _measuredContentHeight ?? _defaultPlayerContentHeight;
          final collapsedTotalPx = _grabberHeight + contentH + bottomClearance;
          final collapsedSize =
              (collapsedTotalPx / math.max(availHeight, 360.0))
                  .clamp(0.24, 0.82);
          final minChildSize = math.min(0.20, collapsedSize * 0.75);
          _currentCollapsedSize = collapsedSize;
          _scheduleMeasurePlayerHeight(availHeight, bottomClearance);

          return DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize:
                widget.initialExpanded ? _expandedSize : collapsedSize,
            minChildSize: minChildSize,
            maxChildSize: _expandedSize,
            snap: true,
            snapSizes: [collapsedSize, _expandedSize],
            expand: false,
            builder: (context, scrollController) {
              _activeScrollController = scrollController;

              return Container(
                decoration: BoxDecoration(
                  color: sheetBg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: CustomScrollView(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  slivers: [
                    // 1. 置頂拖曳把手
                    PinnedHeaderSliver(
                      child: ColoredBox(
                        color: sheetBg,
                        child: SizedBox(
                          height: _grabberHeight,
                          child: Center(
                            child: Container(
                              width: 38,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF3A3E4D)
                                    : const Color(0xFFDDD5C7),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 2. 音樂播放器核心區塊（精準貼合內容高度，無多餘空白）
                    SliverToBoxAdapter(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          KeyedSubtree(
                            key: _playerContentKey,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 圓形禪意圖騰
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      color: primary.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: primary.withValues(alpha: 0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.spa_rounded,
                                        color: primary,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // 曲名
                                  Text(
                                    '#${(song.id + 1).toString().padLeft(2, '0')} ${song.title}',
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${song.artist} · ${song.album} · 每拍 ${(song.effectiveBeatIntervalMs / 1000).toStringAsFixed(2)} 秒',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? const Color(0xFFA3A199)
                                          : const Color(0xFF756F68),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // 進度條與時間顯示（局部重繪，播放與拖曳期間不觸發歌單與面板重建）
                                  ListenableBuilder(
                                    listenable: Listenable.merge([
                                      vm.audioPositionListenable,
                                      vm.audioDurationListenable,
                                      _dragValueNotifier,
                                    ]),
                                    builder: (context, _) {
                                      final position =
                                          vm.audioPositionListenable.value;
                                      final duration =
                                          vm.audioDurationListenable.value;
                                      final dragVal = _dragValueNotifier.value;
                                      final maxMs =
                                          (duration.inMilliseconds > 0)
                                              ? duration.inMilliseconds
                                                  .toDouble()
                                              : 1000.0;
                                      final curMs = position.inMilliseconds
                                          .toDouble()
                                          .clamp(0.0, maxMs);

                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SliderTheme(
                                            data: SliderTheme.of(context)
                                                .copyWith(
                                              trackHeight: 4,
                                              thumbShape:
                                                  const RoundSliderThumbShape(
                                                enabledThumbRadius: 6,
                                              ),
                                              overlayShape:
                                                  const RoundSliderOverlayShape(
                                                overlayRadius: 14,
                                              ),
                                            ),
                                            child: Slider(
                                              value: (dragVal ?? curMs)
                                                  .clamp(0.0, maxMs),
                                              min: 0.0,
                                              max: maxMs,
                                              onChangeStart: (val) {
                                                _dragValueNotifier.value = val;
                                                vm.beginScrubbing();
                                              },
                                              onChanged: (val) {
                                                _dragValueNotifier.value = val;
                                              },
                                              onChangeEnd: (val) {
                                                final targetMs = val.toInt();
                                                _dragValueNotifier.value = null;
                                                vm.endScrubbing(
                                                  Duration(
                                                    milliseconds: targetMs,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  _formatDuration(
                                                    dragVal != null
                                                        ? Duration(
                                                            milliseconds:
                                                                dragVal.toInt(),
                                                          )
                                                        : position,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark
                                                        ? const Color(
                                                            0xFFA3A199)
                                                        : const Color(
                                                            0xFF756F68),
                                                  ),
                                                ),
                                                Text(
                                                  _formatDuration(duration),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark
                                                        ? const Color(
                                                            0xFFA3A199)
                                                        : const Color(
                                                            0xFF756F68),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 6),

                                  // 播控按鈕列
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // 循環模式
                                      IconButton(
                                        icon: Icon(
                                          releaseMode == ReleaseMode.loop
                                              ? Icons.repeat_one_rounded
                                              : Icons.repeat_rounded,
                                          color: releaseMode == ReleaseMode.loop
                                              ? primary
                                              : theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.4),
                                        ),
                                        tooltip: releaseMode == ReleaseMode.loop
                                            ? '單曲循環'
                                            : '清單播放',
                                        onPressed: () => vm.toggleAudioLoop(),
                                      ),
                                      // 倒退 10 秒
                                      IconButton(
                                        icon: const Icon(
                                          Icons.replay_10_rounded,
                                        ),
                                        tooltip: '倒退 10 秒',
                                        onPressed: () =>
                                            vm.seekAudioRelative(-10),
                                      ),
                                      // 上一首
                                      IconButton(
                                        icon: const Icon(
                                          Icons.skip_previous_rounded,
                                          size: 28,
                                        ),
                                        tooltip: '上一首',
                                        onPressed: () => vm.playPreviousSong(),
                                      ),
                                      // 播放 / 暫停
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            isChantPlaying
                                                ? Icons.pause_rounded
                                                : Icons.play_arrow_rounded,
                                            color: isDark
                                                ? Colors.black
                                                : Colors.white,
                                            size: 30,
                                          ),
                                          tooltip:
                                              isChantPlaying ? '暫停' : '播放',
                                          onPressed: () =>
                                              vm.toggleChant(currentSongId),
                                        ),
                                      ),
                                      // 下一首
                                      IconButton(
                                        icon: const Icon(
                                          Icons.skip_next_rounded,
                                          size: 28,
                                        ),
                                        tooltip: '下一首',
                                        onPressed: () => vm.playNextSong(),
                                      ),
                                      // 快轉 10 秒
                                      IconButton(
                                        icon: const Icon(
                                          Icons.forward_10_rounded,
                                        ),
                                        tooltip: '快轉 10 秒',
                                        onPressed: () =>
                                            vm.seekAudioRelative(10),
                                      ),
                                      // 展開/收合選曲選單
                                      IconButton(
                                        icon: Icon(
                                          _isExpanded
                                              ? Icons.expand_more_rounded
                                              : Icons.playlist_play_rounded,
                                          color: primary,
                                        ),
                                        tooltip:
                                            _isExpanded ? '收合佛曲選單' : '展開佛曲選單',
                                        onPressed: _toggleSheetExpansion,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // 底部上滑展開 / 收合提示條
                                  InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: _toggleSheetExpansion,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primary.withValues(
                                          alpha: isDark ? 0.14 : 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _isExpanded
                                                ? Icons
                                                    .keyboard_arrow_down_rounded
                                                : Icons
                                                    .keyboard_arrow_up_rounded,
                                            size: 18,
                                            color: primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _isExpanded
                                                ? '佛曲選單（共 ${ChantConstants.allSongs.length} 首） · 點擊收合'
                                                : '上滑展開佛曲選單（共 ${ChantConstants.allSongs.length} 首）',
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
                            ),
                          ),
                          SizedBox(
                            height: _isExpanded ? 10.0 : bottomClearance,
                          ),
                        ],
                      ),
                    ),

                    // 3. 置頂吸附之搜尋列與分類標籤篩選列 (Pinned Header)
                    PinnedHeaderSliver(
                      child: ColoredBox(
                        color: sheetBg,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            // 搜尋輸入框與置頂收合回播放器按鈕
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      onTap: _expandSheetIfNeeded,
                                      decoration: InputDecoration(
                                        hintText: '搜尋佛曲名稱、法師或標籤...',
                                        hintStyle: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? const Color(0xFF7E828E)
                                              : const Color(0xFF9E9991),
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.search_rounded,
                                          size: 20,
                                        ),
                                        suffixIcon: _keyword.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(
                                                  Icons.clear,
                                                  size: 18,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _searchController.clear();
                                                    _keyword = '';
                                                  });
                                                },
                                              )
                                            : null,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        filled: true,
                                        fillColor: isDark
                                            ? const Color(0xFF242732)
                                            : const Color(0xFFF7F3EB),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      onChanged: (val) {
                                        _expandSheetIfNeeded();
                                        setState(() => _keyword = val);
                                      },
                                    ),
                                  ),
                                  if (_isExpanded) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      tooltip: '收合回播放器',
                                      style: IconButton.styleFrom(
                                        backgroundColor: isDark
                                            ? const Color(0xFF242732)
                                            : const Color(0xFFF7F3EB),
                                      ),
                                      icon: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: primary,
                                      ),
                                      onPressed: _toggleSheetExpansion,
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // 標籤分類篩選列
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  _buildTagChip(
                                    label:
                                        '全部 (${ChantConstants.allSongs.length})',
                                    tagValue: null,
                                  ),
                                  for (final tag in availableTags) ...[
                                    const SizedBox(width: 8),
                                    _buildTagChip(
                                      label:
                                          '$tag (${ChantConstants.countSongsByTag(tag)})',
                                      tagValue: tag,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                          ],
                        ),
                      ),
                    ),

                    // 4. 佛曲清單列表
                    if (filteredSongs.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: Text(
                              '無相符佛曲',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFFA3A199)
                                    : const Color(0xFF756F68),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.only(
                          top: 4,
                          bottom: MediaQuery.paddingOf(context).bottom + 20,
                        ),
                        sliver: SliverList.builder(
                          itemCount: filteredSongs.length,
                          itemBuilder: (ctx, idx) {
                            final s = filteredSongs[idx];
                            final isSel = currentSongId == s.id;
                            return SongListTile(
                              song: s,
                              isSelected: isSel,
                              isPlaying: isChantPlaying,
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
            },
          );
        },
      ),
    );
  }

  Widget _buildTagChip({
    required String label,
    required String? tagValue,
  }) {
    final isSel = _selectedTag == tagValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      onSelected: (val) {
        _expandSheetIfNeeded();
        setState(() {
          // 再次點擊已選取的分類標籤時可切回「全部」
          if (tagValue != null && _selectedTag == tagValue && !val) {
            _selectedTag = null;
          } else {
            _selectedTag = tagValue;
          }
        });
      },
      visualDensity: VisualDensity.compact,
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
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _checkAndStartScroll());
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
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted ||
          _scrollCycleId != cycleId ||
          !_scrollController.hasClients) {
        return;
      }
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent <= 0) return;

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

      if (!mounted ||
          _scrollCycleId != cycleId ||
          !_scrollController.hasClients) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted ||
          _scrollCycleId != cycleId ||
          !_scrollController.hasClients) {
        return;
      }

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
