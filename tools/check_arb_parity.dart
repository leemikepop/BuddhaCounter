// ARB 翻譯檔一致性檢查：
// 1. app_zh (範本) / app_zh_Hans / app_en 的訊息 key 集合必須完全相同
// 2. 翻譯中出現的 {placeholder} 必須宣告於範本的 @key.placeholders
// 用法：dart tools/check_arb_parity.dart  (或 bash tools/check_arb_parity.sh)
import 'dart:convert';
import 'dart:io';

const template = 'lib/l10n/app_zh.arb';
const translations = ['lib/l10n/app_zh_Hans.arb', 'lib/l10n/app_en.arb'];

Map<String, dynamic> _load(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

/// 取出訊息中「頂層」的 placeholder 名稱 (略過 ICU plural/select 分支內的文字)
Set<String> _placeholdersUsed(String message) {
  final names = <String>{};
  final re = RegExp(r'\{\s*([A-Za-z_][A-Za-z0-9_]*)\s*[,}]');
  for (final m in re.allMatches(message)) {
    names.add(m.group(1)!);
  }
  return names;
}

void main() {
  final tpl = _load(template);
  final tplKeys = _messageKeys(tpl);
  final problems = <String>[];

  for (final path in translations) {
    final arb = _load(path);
    final keys = _messageKeys(arb);
    for (final k in tplKeys.difference(keys)) {
      problems.add('$path: 缺少 key "$k"');
    }
    for (final k in keys.difference(tplKeys)) {
      problems.add('$path: 範本沒有的 key "$k"');
    }
    for (final k in keys.intersection(tplKeys)) {
      final meta = tpl['@$k'];
      final declared = <String>{
        if (meta is Map && meta['placeholders'] is Map)
          ...(meta['placeholders'] as Map).keys.cast<String>(),
      };
      final used = _placeholdersUsed(arb[k].toString());
      for (final p in used.difference(declared)) {
        problems.add('$path: "$k" 使用了範本未宣告的 placeholder {$p}');
      }
    }
  }

  for (final k in tplKeys) {
    final meta = tpl['@$k'];
    if (meta is! Map || (meta['description'] ?? '').toString().isEmpty) {
      problems.add('$template: "$k" 缺少 @$k.description');
    }
  }

  if (problems.isEmpty) {
    stdout.writeln('ARB parity OK (${tplKeys.length} keys)');
    return;
  }
  problems.forEach(stderr.writeln);
  exitCode = 1;
}
