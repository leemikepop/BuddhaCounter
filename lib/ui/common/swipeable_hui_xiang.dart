import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../core/constants/chant_songs.dart';
import '../../l10n/l10n.dart';

/// 支援左右循環滑動切換、且高度隨偈頌行數平滑自適應（無多餘空白）之迴向文輪播組件
class SwipeableHuiXiangCarousel extends StatefulWidget {
  final List<HuiXiangItem> items;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;
  final Color accentColor;
  final TextStyle titleStyle;
  final TextStyle verseStyle;
  final double verseVerticalPadding;
  final double titleBottomSpacing;
  final bool showLotusIcons;

  const SwipeableHuiXiangCarousel({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.onIndexChanged,
    required this.accentColor,
    required this.titleStyle,
    required this.verseStyle,
    this.verseVerticalPadding = 4.0,
    this.titleBottomSpacing = 16.0,
    this.showLotusIcons = true,
  });

  @override
  State<SwipeableHuiXiangCarousel> createState() =>
      _SwipeableHuiXiangCarouselState();
}

class _SwipeableHuiXiangCarouselState extends State<SwipeableHuiXiangCarousel> {
  static const int _kLoopMultiplier = 500;

  late final PageController _pageController;
  final Map<int, double> _measuredHeights = {};
  late int _activeIndex;

  int get _basePage => widget.items.length * _kLoopMultiplier;

  @override
  void initState() {
    super.initState();
    final count = widget.items.length;
    _activeIndex = count > 0 ? widget.initialIndex.clamp(0, count - 1) : 0;
    _pageController = PageController(
      initialPage: count > 1 ? _basePage + _activeIndex : _activeIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  double _estimateHeight(int itemIndex) {
    final measured = _measuredHeights[itemIndex];
    if (measured != null && measured > 0) return measured;
    final item = widget.items[itemIndex];
    final fontSize = widget.verseStyle.fontSize ?? 16.0;
    final lineHeight = widget.verseStyle.height ?? 1.5;
    final perLine = fontSize * lineHeight + widget.verseVerticalPadding * 2;
    return 44.0 +
        widget.titleBottomSpacing +
        item.verses.length * perLine +
        6.0;
  }

  double _computeCurrentHeight() {
    final count = widget.items.length;
    if (count == 0) return 0;
    if (count == 1) return _estimateHeight(0);

    double page = (_basePage + _activeIndex).toDouble();
    if (_pageController.hasClients &&
        _pageController.position.haveDimensions &&
        _pageController.page != null) {
      page = _pageController.page!;
    }

    final floorPage = page.floor();
    final ceilPage = page.ceil();
    final t = (page - floorPage).clamp(0.0, 1.0);
    final floorIdx = ((floorPage % count) + count) % count;
    final ceilIdx = ((ceilPage % count) + count) % count;
    return ui.lerpDouble(
          _estimateHeight(floorIdx),
          _estimateHeight(ceilIdx),
          t,
        ) ??
        _estimateHeight(_activeIndex);
  }

  void _updateMeasuredHeight(int itemIndex, double height) {
    if (!mounted || height <= 0) return;
    final prev = _measuredHeights[itemIndex];
    if (prev == null || (prev - height).abs() > 0.5) {
      setState(() {
        _measuredHeights[itemIndex] = height;
      });
    }
  }

  void _goPrevious() {
    if (!_pageController.hasClients || widget.items.length <= 1) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _goNext() {
    if (!_pageController.hasClients || widget.items.length <= 1) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _jumpToItem(int targetIdx) {
    final count = widget.items.length;
    if (!_pageController.hasClients ||
        count <= 1 ||
        targetIdx == _activeIndex) {
      return;
    }
    final currentPage =
        (_pageController.page ?? (_basePage + _activeIndex)).round();
    final currentMod = ((currentPage % count) + count) % count;
    final delta = targetIdx - currentMod;
    _pageController.animateToPage(
      currentPage + delta,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.items.length;
    if (count == 0) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListenableBuilder(
          listenable: _pageController,
          builder: (context, child) {
            return SizedBox(
              height: _computeCurrentHeight(),
              child: child,
            );
          },
          child: PageView.builder(
            controller: _pageController,
            physics: count > 1
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            itemCount: count > 1 ? null : 1,
            onPageChanged: (rawPage) {
              final nextIdx = ((rawPage % count) + count) % count;
              if (_activeIndex != nextIdx) {
                setState(() {
                  _activeIndex = nextIdx;
                });
              }
              widget.onIndexChanged?.call(nextIdx);
            },
            itemBuilder: (context, rawPage) {
              final itemIdx = ((rawPage % count) + count) % count;
              final item = widget.items[itemIdx];

              return SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: _MeasureSize(
                  onChange: (size) =>
                      _updateMeasuredHeight(itemIdx, size.height),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 標題與左右切換箭頭
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (count > 1)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              tooltip: context.l10n.huiXiangPrevTooltip,
                              icon: Icon(
                                Icons.chevron_left_rounded,
                                size: 22,
                                color:
                                    widget.accentColor.withValues(alpha: 0.7),
                              ),
                              onPressed: _goPrevious,
                            ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.showLotusIcons) ...[
                                  Icon(
                                    Icons.spa_outlined,
                                    size: 20,
                                    color: widget.accentColor,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Text(
                                    item.title,
                                    textAlign: TextAlign.center,
                                    style: widget.titleStyle,
                                  ),
                                ),
                                if (widget.showLotusIcons) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.spa_outlined,
                                    size: 20,
                                    color: widget.accentColor,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (count > 1)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              tooltip: context.l10n.huiXiangNextTooltip,
                              icon: Icon(
                                Icons.chevron_right_rounded,
                                size: 22,
                                color:
                                    widget.accentColor.withValues(alpha: 0.7),
                              ),
                              onPressed: _goNext,
                            ),
                        ],
                      ),
                      SizedBox(height: widget.titleBottomSpacing),

                      // 迴向偈頌文句
                      for (final verse in item.verses)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: widget.verseVerticalPadding,
                          ),
                          child: Text(
                            verse,
                            textAlign: TextAlign.center,
                            style: widget.verseStyle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // 分頁指示點
        if (count > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(count, (idx) {
              final isSelected = idx == _activeIndex;
              return GestureDetector(
                onTap: () => _jumpToItem(idx),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: isSelected ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? widget.accentColor
                          : widget.accentColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _MeasureSize extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onChange;

  const _MeasureSize({
    required this.onChange,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMeasureSize(onChange);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderMeasureSize renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  ValueChanged<Size> onChange;
  Size? _prevSize;

  _RenderMeasureSize(this.onChange);

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size;
    if (newSize != null && _prevSize != newSize) {
      _prevSize = newSize;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChange(newSize);
      });
    }
  }
}
