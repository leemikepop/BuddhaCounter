import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/counter/counter_view_model.dart';
import '../../l10n/l10n.dart';

/// 語言選項名稱：「跟隨系統」依目前語言翻譯，其餘一律以該語言本身顯示
String appLanguageLabel(AppLocalizations l10n, AppLanguage v) {
  switch (v) {
    case AppLanguage.system:
      return l10n.languageFollowSystem;
    case AppLanguage.zhHant:
      return '繁體中文';
    case AppLanguage.zhHans:
      return '简体中文';
    case AppLanguage.en:
      return 'English';
  }
}

/// 語言選擇底部面板 (現代模式 Drawer 與經典模式設定頁共用)
Future<void> showLanguagePicker(BuildContext context) {
  final vm = context.read<CounterViewModel>();
  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final l10n = ctx.l10n;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Text(
                  l10n.languageMenuTitle,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              RadioGroup<AppLanguage>(
                groupValue: vm.appLanguage,
                onChanged: (v) {
                  if (v == null) return;
                  vm.setAppLanguage(v);
                  Navigator.pop(ctx);
                },
                child: Column(
                  children: [
                    for (final v in AppLanguage.values)
                      RadioListTile<AppLanguage>(
                        value: v,
                        title: Text(appLanguageLabel(l10n, v)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
