import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/chant_songs.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/counter/counter_view_model.dart';
import '../../common/app_toast.dart';

/// 現代禪意【迴向】專屬視圖
/// 包含：阿彌陀佛聖像、大回向西方文（與 Legacy 一致）、合十祈願與引磬敲響
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // 阿彌陀佛聖像 (與 Legacy 一致)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/amitabha735x659.jpg',
              height: 260,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/amitabha768x1024.png',
                height: 260,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 經卷書風：大回向西方文 (與 Legacy 一致)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
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
                // 大回向西方文 標題
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.spa_outlined, size: 20, color: primary),
                    const SizedBox(width: 8),
                    Text(
                      ChantConstants.huiXiangTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.spa_outlined, size: 20, color: primary),
                  ],
                ),
                const SizedBox(height: 20),

                // 回向偈頌文句
                ...ChantConstants.huiXiangVerses.map(
                  (verse) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      verse,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.8,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                        color: isDark
                            ? const Color(0xFFE2E2E6)
                            : const Color(0xFF333333),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // 南無阿彌陀佛
                Text(
                  '南無阿彌陀佛',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3.0,
                    color: primary,
                  ),
                ),

                const SizedBox(height: 24),

                // 合十祈願 · 敲響引磬
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    vm.audioService.playClickSfx(SoundEffectType.bell);
                    AppToast.show(context, '阿彌陀佛，合十迴向功德圓滿');
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


