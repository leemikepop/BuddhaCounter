import 'package:buddha_counter/ui/modern/theme/modern_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // AppBar 標題沒指定字型時，引擎會改用平台預設字型，和其他文字不一致
  // (截圖測試裡更會畫成方框)，所以標題要沿用 textTheme 的字型
  for (final (name, theme) in [
    ('light', ModernTheme.lightTheme),
    ('dark', ModernTheme.darkTheme),
  ]) {
    test('$name AppBar title uses the text theme font family', () {
      final title = theme.appBarTheme.titleTextStyle!;
      expect(title.fontFamily, isNotNull);
      expect(title.fontFamily, theme.textTheme.titleLarge!.fontFamily);
      expect(title.fontSize, 18);
    });
  }
}
