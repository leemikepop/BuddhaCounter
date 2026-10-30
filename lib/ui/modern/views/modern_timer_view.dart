import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/chant_songs.dart';
import '../../../features/counter/counter_view_model.dart';
import '../../common/app_toast.dart';

/// 現代禪意【自動計數】專屬視圖
/// 版面風格統一模仿手動計數：頂部碼表、圓形計數盤、下方大播放鈕與定時設定
class ModernTimerView extends StatelessWidget {
  const ModernTimerView({super.key});

  void _showStopTimerPicker(BuildContext context, CounterViewModel vm) {
    final minutesOptions = [0, 15, 30, 45, 60, 90];
    final customController = TextEditingController(
      text: (!minutesOptions.contains(vm.autoStopMinutes) && vm.autoStopMinutes > 0)
          ? vm.autoStopMinutes.toString()
          : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '設定定時停止時長',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ...minutesOptions.map((m) {
                        final label = (m == 0) ? '持續播放' : '$m 分鐘';
                        final isSel = vm.autoStopMinutes == m;
                        return ChoiceChip(
                          label: Text(label),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) {
                              vm.setAutoStopMinutes(m);
                              Navigator.pop(ctx);
                              AppToast.show(
                                context,
                                m == 0 ? '已設定為持續播放' : '已設定定時停止：$m 分鐘',
                              );
                            }
                          },
                        );
                      }),
                      if (!minutesOptions.contains(vm.autoStopMinutes) &&
                          vm.autoStopMinutes > 0)
                        ChoiceChip(
                          label: Text('${vm.autoStopMinutes} 分鐘 (自訂)'),
                          selected: true,
                          onSelected: (_) {},
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    '或自訂分鐘數：',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(ctx).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: TextField(
                            controller: customController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              hintText: '輸入分鐘數 (如 20)',
                              suffixText: '分鐘',
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF242732)
                                  : const Color(0xFFF7F3EB),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          final mins = int.tryParse(customController.text.trim());
                          if (mins != null && mins > 0) {
                            vm.setAutoStopMinutes(mins);
                            Navigator.pop(ctx);
                            AppToast.show(context, '已設定定時停止：$mins 分鐘');
                          } else {
                            AppToast.show(context, '請輸入大於 0 的有效分鐘數');
                          }
                        },
                        child: const Text('設定'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmResetAutoCount(BuildContext context, CounterViewModel vm) {
    if (vm.autoCount == 0) {
      AppToast.show(context, '目前計數已為 0');
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重設自動計數？'),
        content: Text('目前自動計數為 ${vm.autoCount} 聲，確定要歸零重置嗎？\n（計時時間將會保留）'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton.tonal(
            onPressed: () {
              Navigator.pop(ctx);
              vm.resetAutoCount();
              AppToast.show(context, '自動計數已重置為 0');
            },
            child: const Text('確認重置'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CounterViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final song = ChantConstants.getSongById(vm.currentSongId);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          // 頂部碼表（模仿手動計數：時鐘圖示、計時數字、開始/暫停鈕、歸零鈕，無文字）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2027) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF2E323E) : const Color(0xFFEFE8DC),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : primary.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 20,
                  color: primary,
                ),
                const SizedBox(width: 8),
                Text(
                  vm.formattedAutoTimer,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: theme.colorScheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 14),
                // 開始 / 暫停按鈕 (與下方大按鈕同步)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    vm.isAutoCounting
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: primary,
                    size: 26,
                  ),
                  tooltip: vm.isAutoCounting ? '暫停' : '開始',
                  onPressed: () => vm.toggleAutoCount(),
                ),
                const SizedBox(width: 10),
                // 計時重置按鈕（維持計時重置，不影響計數）
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.replay_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  tooltip: '重設計時',
                  onPressed: () {
                    vm.resetAutoTimer();
                    AppToast.show(context, '計時已重置');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 核心圓形計數盤（模仿手動計數圓盤視覺風格，移除動態轉圈進度環，消弭卡頓）
          RepaintBoundary(
            child: GestureDetector(
              onTap: () => vm.toggleAutoCount(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF282B34),
                            const Color(0xFF1B1D23),
                          ]
                        : [
                            surface,
                            const Color(0xFFF7F2E9),
                          ],
                  ),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF383C48)
                        : const Color(0xFFEDE5D8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.4)
                          : primary.withValues(alpha: 0.12),
                      blurRadius: 32,
                      spreadRadius: 4,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      vm.isAutoCounting
                          ? Icons.auto_mode_rounded
                          : Icons.spa_rounded,
                      size: 26,
                      color: primary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 8),
                    // 數字顯示（自動調整大字）
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          vm.autoCount.toString(),
                          style: TextStyle(
                            fontSize: 62,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.0,
                            color: theme.colorScheme.onSurface,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '聲 · 遍',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFFA3A199)
                            : const Color(0xFF756F68),
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 當前曲目節拍小標籤
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '每拍 ${(song.effectiveBeatIntervalMs / 1000).toStringAsFixed(2)}s 自動累加',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 定時停止設定按鈕（模仿手動計數目標按鈕，底附倒數進度條）
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF21232B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF323642)
                    : const Color(0xFFEBE3D5),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: InkWell(
                onTap: () => _showStopTimerPicker(context, vm),
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.hourglass_bottom_rounded,
                                size: 15, color: primary),
                            const SizedBox(width: 6),
                            Text(
                              vm.autoStopMinutes > 0
                                  ? '定時停止：${vm.autoStopMinutes} 分鐘'
                                  : '定時停止：持續播放',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_drop_down, size: 16, color: primary),
                          ],
                        ),
                      ),
                      if (vm.autoStopMinutes > 0)
                        RepaintBoundary(
                          child: SizedBox(
                            height: 2.5,
                            child: LinearProgressIndicator(
                              value: vm.autoStopProgress,
                              minHeight: 2.5,
                              backgroundColor: isDark
                                  ? const Color(0xFF2E313D)
                                  : const Color(0xFFEDE4D5),
                              valueColor: AlwaysStoppedAnimation<Color>(primary),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 圓形計數盤下方的主控制按鈕列：左邊「重置」計數，右邊「開始」/「暫停」（字數皆為 2 字對齊）
          Row(
            children: [
              // 左邊：計數重置按鈕 (2個字)
              Expanded(
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () => _confirmResetAutoCount(context, vm),
                  icon: const Icon(Icons.restart_alt_rounded, size: 22),
                  label: const Text(
                    '重置',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // 右邊：開始 / 暫停按鈕 (2個字)
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: vm.isAutoCounting ? 0 : 3,
                    shadowColor: primary.withValues(alpha: 0.3),
                  ),
                  onPressed: () => vm.toggleAutoCount(),
                  icon: Icon(
                    vm.isAutoCounting
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 24,
                  ),
                  label: Text(
                    vm.isAutoCounting ? '暫停' : '開始',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
