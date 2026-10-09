import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/counter/counter_view_model.dart';

/// 現代禪意【迴向】專屬視圖
/// 包含：莊嚴迴向文經卷、合十祈願與引磬敲響
class ModernPracticeView extends StatelessWidget {
  const ModernPracticeView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          // 經卷書風：經典迴向文
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF232630), const Color(0xFF191B22)]
                    : [const Color(0xFFFBF8F2), const Color(0xFFF3ECE0)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? const Color(0xFF333744) : const Color(0xFFE8DFCF),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : primary.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.spa_outlined, size: 20, color: primary),
                    const SizedBox(width: 8),
                    Text(
                      '普皆迴向 · 功德無量',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3.0,
                        color: primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.spa_outlined, size: 20, color: primary),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  '願以此功德，莊嚴佛淨土。\n'
                  '上報四重恩，下濟三途苦。\n'
                  '若有見聞者，悉發菩提心。\n'
                  '盡此一報身，同生極樂國。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    height: 2.2,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 4.0,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    vm.audioService.playClickSfx(SoundEffectType.bell);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('阿彌陀佛，合十迴向功德圓滿')),
                    );
                  },
                  icon: const Icon(Icons.favorite_outline_rounded, size: 18),
                  label: const Text('合十祈願 · 敲響引磬', style: TextStyle(fontSize: 15)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}


