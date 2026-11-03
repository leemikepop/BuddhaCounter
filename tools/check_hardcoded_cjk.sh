#!/usr/bin/env bash
# 檢查 Dart 程式碼中是否仍有寫死的中日韓 (CJK) 字串常值。
# 使用者可見文字應改走 lib/l10n (ARB) 或 lib/core/content (曲目內容目錄)。
# 用法：bash tools/check_hardcoded_cjk.sh [檔案或目錄 ...]   (預設掃描 lib/)
# 有發現時列出「檔案:行號:內容」並以 exit 1 結束。
# 刻意不翻譯的字串 (例如語言名稱「繁體中文」) 在同一行加註 `// i18n-ignore: <原因>`。
set -uo pipefail
cd "$(dirname "$0")/.."
targets=("$@")
[ ${#targets[@]} -eq 0 ] && targets=(lib)

found=$(grep -rHnP --include='*.dart' "(['\"])[^'\"]*[\x{3400}-\x{9fff}\x{f900}-\x{faff}]" "${targets[@]}" 2>/dev/null \
  | grep -v '^lib/l10n/' \
  | grep -v '^lib/core/content/' \
  | grep -v '^lib/core/constants/chant_songs.dart:' \
  | grep -vP '^[^:]+:\d+:\s*//' \
  | grep -v 'i18n-ignore' )

if [ -n "$found" ]; then
  echo "$found"
  exit 1
fi
exit 0
