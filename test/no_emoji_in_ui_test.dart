import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 畫面裡不要放 emoji：商店截圖工具 (tool/screenshots) 只有 Noto CJK 字型，
/// flutter_tester 也不會逐字改用其他字型，emoji 會畫成方框。要圖示請用 Icons.*。
void main() {
  test('lib/ui 沒有 emoji', () {
    final emoji =
        RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true);
    final offenders = <String>[];
    for (final f in Directory('lib/ui').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (emoji.hasMatch(lines[i])) offenders.add('${f.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty);
  });
}
