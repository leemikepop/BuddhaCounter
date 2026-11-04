import 'package:flutter/material.dart';

/// 單行文字太長時自動左右來回捲動的跑馬燈 (放不下才會捲)
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
