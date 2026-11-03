import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/l10n.dart';
import '../../common/app_toast.dart';

/// 共用的「預設值選項 + 自訂數字輸入」區塊
/// 用於手動計數目標、每日功課目標、自動計數停止條件 (聲數 / 時間)
class PresetValuePicker extends StatefulWidget {
  /// 預設選項 (0 代表「不限」，僅在 [zeroLabel] 不為 null 時顯示)
  final List<int> presets;

  /// 目前設定值 (0 = 未設定)
  final int current;

  /// 選項晶片的顯示文字
  final String Function(int value) chipLabel;

  /// 自訂數值晶片的顯示文字 (目前值不在預設選項中時顯示)
  final String Function(int value) customChipLabel;

  /// 0 值選項的顯示文字；為 null 則不顯示 0 選項
  final String? zeroLabel;

  final String customPrompt;
  final String hintText;
  final String suffixText;
  final String invalidMessage;

  /// 選定數值 (含 0)
  final ValueChanged<int> onSelected;

  /// 再次點選已選取的晶片時觸發 (取消選取)；為 null 則不可取消
  final VoidCallback? onDeselected;

  const PresetValuePicker({
    super.key,
    required this.presets,
    required this.current,
    required this.chipLabel,
    required this.customChipLabel,
    required this.customPrompt,
    required this.hintText,
    required this.suffixText,
    required this.invalidMessage,
    required this.onSelected,
    this.zeroLabel,
    this.onDeselected,
  });

  @override
  State<PresetValuePicker> createState() => _PresetValuePickerState();
}

class _PresetValuePickerState extends State<PresetValuePicker> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitCustom() {
    final val = int.tryParse(_controller.text.trim());
    if (val != null && val > 0) {
      widget.onSelected(val);
    } else {
      AppToast.show(context, widget.invalidMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final options = [
      ...widget.presets.where((v) => v > 0),
      if (widget.zeroLabel != null) 0,
    ];
    final isCustom = widget.current > 0 && !options.contains(widget.current);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...options.map((v) {
              final isSel = widget.current == v;
              return ChoiceChip(
                label: Text(v == 0 ? widget.zeroLabel! : widget.chipLabel(v)),
                selected: isSel,
                onSelected: (val) {
                  if (val) {
                    widget.onSelected(v);
                  } else if (widget.onDeselected != null) {
                    widget.onDeselected!();
                  }
                },
              );
            }),
            if (isCustom)
              ChoiceChip(
                label: Text(widget.customChipLabel(widget.current)),
                selected: true,
                onSelected: (val) {
                  if (!val && widget.onDeselected != null) {
                    widget.onDeselected!();
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          widget.customPrompt,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    suffixText: widget.suffixText,
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
                  onSubmitted: (_) => _submitCustom(),
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
              onPressed: _submitCustom,
              child: Text(context.l10n.commonSet),
            ),
          ],
        ),
      ],
    );
  }
}

/// 底部面板外框：標題列 + 關閉鈕 + 內容，含鍵盤避讓與安全區域
Future<void> showGoalSheet(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
          top: 20,
          left: 16,
          right: 16,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Text(
                        title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: context.l10n.commonClose,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                builder(ctx),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// 聲數目標選擇面板 (手動計數目標、每日功課目標共用)
Future<void> showCountGoalPicker(
  BuildContext context, {
  required String title,
  required int current,
  required ValueChanged<int> onSelected,
}) {
  return showGoalSheet(
    context,
    title: title,
    builder: (ctx) {
      final l10n = ctx.l10n;
      return PresetValuePicker(
        presets: const [108, 500, 1000, 5000, 10000],
        zeroLabel: l10n.goalUnlimited,
        current: current,
        chipLabel: (v) => '$v',
        customChipLabel: l10n.goalCustomChip,
        customPrompt: l10n.goalCustomPrompt,
        hintText: l10n.goalCustomHint,
        suffixText: l10n.unitRecitationsSuffix,
        invalidMessage: l10n.goalInvalidNumber,
        onSelected: (v) {
          onSelected(v);
          Navigator.pop(ctx);
          AppToast.show(
            context,
            v == 0 ? l10n.goalSetUnlimitedToast : l10n.goalSetToast(v),
          );
        },
      );
    },
  );
}
