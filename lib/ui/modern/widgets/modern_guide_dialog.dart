import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/counter/counter_view_model.dart';

/// 現代模式新版介面功能導覽引導教學 (Interactive Onboarding Guide)
class ModernGuideDialog extends StatefulWidget {
  final VoidCallback? onComplete;

  const ModernGuideDialog({
    super.key,
    this.onComplete,
  });

  /// 呼叫顯示引導教學對話框
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onComplete,
  }) {
    final vm = context.read<CounterViewModel>();
    vm.markModernGuideSeen();

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ModernGuideDialog(onComplete: onComplete),
    );
  }

  @override
  State<ModernGuideDialog> createState() => _ModernGuideDialogState();
}

class _ModernGuideDialogState extends State<ModernGuideDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_GuideSlideData> _slides = const [
    _GuideSlideData(
      icon: Icons.spa_rounded,
      badgeText: '全新升級',
      title: '全新現代操作介面',
      description: '為精進念佛特別重塑的視覺與互動體驗，簡約優雅。',
      items: [
        _GuideItem(
          icon: Icons.adjust_rounded,
          title: '圓環計數',
          subtitle: '流暢呼吸光暈與計數進度，每聲佛號皆清明覺察。',
        ),
        _GuideItem(
          icon: Icons.dark_mode_outlined,
          title: '深色與雙主題',
          subtitle: '溫潤素雅淺色與靜謐曜石深色，護眼舒適。',
        ),
        _GuideItem(
          icon: Icons.timer_outlined,
          title: '修持計時碼表',
          subtitle: '頂部整合極簡碼表，念佛時長一目了然。',
        ),
      ],
    ),
    _GuideSlideData(
      icon: Icons.swipe_rounded,
      badgeText: '左右滑動',
      title: '三大專屬修持分頁',
      description: '左右滑動螢幕或點選下方導覽列，即可在三大修持專頁間自由切換：',
      items: [
        _GuideItem(
          icon: Icons.touch_app_outlined,
          title: '手動計數',
          subtitle: '支援自訂今日目標聲數、全螢幕點擊與引磬木魚聲。',
        ),
        _GuideItem(
          icon: Icons.music_note_rounded,
          title: '自動計數',
          subtitle: '跟隨佛曲節奏同步累計，自訂定時停止與圓滿鐘響。',
        ),
        _GuideItem(
          icon: Icons.favorite_border_rounded,
          title: '迴向發願',
          subtitle: '大回向西方文，功德圓滿。',
        ),
      ],
    ),
    _GuideSlideData(
      icon: Icons.queue_music_rounded,
      badgeText: '實用工具',
      title: '隨身佛曲 · 快捷控制',
      description: '常駐音樂播放器與頂端實用快捷工具，修行更隨心自如：',
      items: [
        _GuideItem(
          icon: Icons.playlist_play_rounded,
          title: '31首經典佛曲隨身聽',
          subtitle: '底部常駐迷你播放器，支援背景持續播放與一鍵選曲。',
        ),
        _GuideItem(
          icon: Icons.remove_red_eye_outlined,
          title: '保持螢幕常亮',
          subtitle: '右上角一鍵開關防止休眠，共修念佛不熄屏。',
        ),
        _GuideItem(
          icon: Icons.screen_lock_rotation_rounded,
          title: '螢幕方向鎖定',
          subtitle: '走動或拜佛計數時鎖定方向，避免畫面誤旋轉。',
        ),
      ],
    ),
    _GuideSlideData(
      icon: Icons.style_outlined,
      badgeText: '自由選擇',
      title: '傳承與創新 · 雙模式自由切換',
      description: '我們完整保留了陪伴大家多年的熟悉介面：',
      items: [
        _GuideItem(
          icon: Icons.history_edu_rounded,
          title: '一鍵切換經典模式',
          subtitle: '點擊右上角「風格切換」按鈕，隨時可切換回經典藍色版面。',
        ),
        _GuideItem(
          icon: Icons.school_outlined,
          title: '選單隨時查閱導覽',
          subtitle: '日後隨時可於側邊抽屜選單點選「新版功能導覽」再次溫習。',
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.of(context).pop();
      widget.onComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Dialog(
      backgroundColor:
          isDark ? const Color(0xFF1E212A) : const Color(0xFFFCFAF7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 440,
          maxHeight: 580,
        ),
        child: Column(
          children: [
            // 頂部小標題與關閉按鈕
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 14, color: primary),
                        const SizedBox(width: 4),
                        Text(
                          '新功能指引',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onComplete?.call();
                    },
                    tooltip: '關閉導覽',
                  ),
                ],
              ),
            ),

            // PageView 內容
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        // 頂部圖示卡片
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(slide.icon, size: 34, color: primary),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black54,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        // 條列重點項目
                        ...slide.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  margin: const EdgeInsets.only(top: 2),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF2B2E3B)
                                        : const Color(0xFFF3ECE0),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    size: 18,
                                    color: primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.subtitle,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: isDark
                                              ? Colors.white60
                                              : Colors.black54,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 底部指示器與按鈕
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF2C2F3A)
                        : const Color(0xFFEFE8DC),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // 圓點指示器
                  Row(
                    children: List.generate(_slides.length, (i) {
                      final isCurrent = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        width: isCurrent ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? primary
                              : (isDark ? Colors.white24 : Colors.black12),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  // 跳過按鈕
                  if (_currentPage < _slides.length - 1)
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onComplete?.call();
                      },
                      child: const Text('跳過'),
                    ),
                  const SizedBox(width: 4),
                  // 下一步 / 開始體驗 按鈕
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _onNext,
                    child: Text(
                      _currentPage == _slides.length - 1 ? '開始體驗' : '下一步',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideSlideData {
  final IconData icon;
  final String badgeText;
  final String title;
  final String description;
  final List<_GuideItem> items;

  const _GuideSlideData({
    required this.icon,
    required this.badgeText,
    required this.title,
    required this.description,
    required this.items,
  });
}

class _GuideItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const _GuideItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
