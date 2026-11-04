import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/chant_songs.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/song_tag_filter_bar.dart';
import '../../theme/modern_palette.dart';
import 'player_controls.dart';
import 'song_menu.dart';

/// 可上下拖曳的播放器面板：
/// - 收合高度剛好放下 [PlayerControls] (高度在第一次排版後實測)
/// - 往上拉到 [_expandedSize] 即展開搜尋、標籤篩選與完整佛曲選單
class PlayerSheet extends StatefulWidget {
  const PlayerSheet({super.key, required this.initiallyExpanded});

  final bool initiallyExpanded;

  static Future<void> show(BuildContext context, {required bool expanded}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlayerSheet(initiallyExpanded: expanded),
    );
  }

  @override
  State<PlayerSheet> createState() => _PlayerSheetState();
}

class _PlayerSheetState extends State<PlayerSheet> {
  static const double _grabberHeight = 22.0;

  /// 實測前用來估算收合高度的播放控制區高度
  static const double _estimatedControlsHeight = 276.0;
  static const double _expandedSize = 0.94;

  final GlobalKey _controlsKey = GlobalKey();
  final DraggableScrollableController _sheet = DraggableScrollableController();
  final TextEditingController _search = TextEditingController();
  ScrollController? _listScroll;

  double? _measuredControlsHeight;
  bool _measureScheduled = false;
  bool _isAnimating = false;
  double _collapsedSize = 0.38;
  late bool _isExpanded = widget.initiallyExpanded;

  String _keyword = '';
  ChantTag? _tag;

  @override
  void initState() {
    super.initState();
    _sheet.addListener(_onSheetSizeChanged);
  }

  @override
  void dispose() {
    _sheet.removeListener(_onSheetSizeChanged);
    _sheet.dispose();
    _search.dispose();
    super.dispose();
  }

  /// 拖過收合與展開的中點，就切換「已展開」狀態 (影響按鈕圖示)
  void _onSheetSizeChanged() {
    if (!_sheet.isAttached) return;
    final expanded = _sheet.size >= (_collapsedSize + _expandedSize) / 2;
    if (expanded != _isExpanded && mounted) {
      setState(() => _isExpanded = expanded);
    }
  }

  double _collapsedSizeFor(
      double controlsHeight, double availHeight, double bottomClearance) {
    final px = _grabberHeight + controlsHeight + bottomClearance;
    return (px / math.max(availHeight, 360.0)).clamp(0.24, 0.82);
  }

  /// 排版後量出播放控制區實際高度，修正收合高度 (不同語言、字級高度不同)
  void _scheduleMeasure(double availHeight, double bottomClearance) {
    if (_measureScheduled) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      if (!mounted) return;
      final box = _controlsKey.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      final height = box.size.height;
      final measured = _measuredControlsHeight;
      if (measured != null && (height - measured).abs() <= 0.5) return;

      final oldCollapsed = _collapsedSize;
      setState(() {
        _measuredControlsHeight = height;
        _collapsedSize =
            _collapsedSizeFor(height, availHeight, bottomClearance);
      });
      // 還停在舊的收合高度時，跳到新的收合高度
      final stillAtOldCollapsed =
          _sheet.isAttached && (_sheet.size - oldCollapsed).abs() < 0.05;
      if (!_isExpanded && !_isAnimating && stillAtOldCollapsed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isExpanded && !_isAnimating && _sheet.isAttached) {
            _sheet.jumpTo(_collapsedSize);
          }
        });
      }
    });
  }

  Future<void> _animateTo(double size, Duration duration) async {
    _isAnimating = true;
    try {
      await _sheet.animateTo(size,
          duration: duration, curve: Curves.easeOutCubic);
    } catch (_) {
      // 面板在動畫中被關閉
    } finally {
      _isAnimating = false;
    }
  }

  Future<void> _expandIfNeeded() async {
    if (!_sheet.isAttached || _sheet.size >= _expandedSize - 0.03) return;
    await _animateTo(_expandedSize, const Duration(milliseconds: 300));
  }

  Future<void> _toggleExpanded() async {
    if (!_sheet.isAttached) return;
    if (!_isExpanded) return _expandIfNeeded();
    final scroll = _listScroll;
    if (scroll != null && scroll.hasClients && scroll.offset > 0) {
      scroll.jumpTo(0);
    }
    await _animateTo(_collapsedSize, const Duration(milliseconds: 280));
  }

  @override
  Widget build(BuildContext context) {
    final palette = ModernPalette.of(context);
    final songs = filterSongs(
      ChantConstants.allSongs,
      l10n: context.l10n,
      tag: _tag,
      keyword: _keyword,
    );
    final bottomClearance =
        math.max(14.0, MediaQuery.paddingOf(context).bottom + 8.0);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availHeight = constraints.maxHeight;
          _collapsedSize = _collapsedSizeFor(
            _measuredControlsHeight ?? _estimatedControlsHeight,
            availHeight,
            bottomClearance,
          );
          _scheduleMeasure(availHeight, bottomClearance);

          return DraggableScrollableSheet(
            controller: _sheet,
            initialChildSize:
                widget.initiallyExpanded ? _expandedSize : _collapsedSize,
            minChildSize: math.min(0.20, _collapsedSize * 0.75),
            maxChildSize: _expandedSize,
            snap: true,
            snapSizes: [_collapsedSize, _expandedSize],
            expand: false,
            builder: (context, scrollController) {
              _listScroll = scrollController;
              return Container(
                decoration: BoxDecoration(
                  color: palette.sheetBackground,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
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
                    PinnedHeaderSliver(child: _Grabber(palette: palette)),
                    SliverToBoxAdapter(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          KeyedSubtree(
                            key: _controlsKey,
                            child: PlayerControls(
                              isMenuExpanded: _isExpanded,
                              onToggleMenu: _toggleExpanded,
                            ),
                          ),
                          SizedBox(
                              height: _isExpanded ? 10.0 : bottomClearance),
                        ],
                      ),
                    ),
                    PinnedHeaderSliver(
                      child: SongMenuHeader(
                        searchController: _search,
                        keyword: _keyword,
                        onKeywordChanged: (v) => setState(() => _keyword = v),
                        selectedTag: _tag,
                        onTagChanged: (t) => setState(() => _tag = t),
                        showCollapseButton: _isExpanded,
                        onCollapse: _toggleExpanded,
                        onInteract: _expandIfNeeded,
                      ),
                    ),
                    SongMenuList(songs: songs),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber({required this.palette});

  final ModernPalette palette;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: palette.sheetBackground,
      child: SizedBox(
        height: _PlayerSheetState._grabberHeight,
        child: Center(
          child: Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: palette.grabber,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
