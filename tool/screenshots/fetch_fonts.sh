#!/usr/bin/env bash
# 下載截圖用的開源字型 (Noto Sans CJK，SIL Open Font License) 到 tool/screenshots/fonts/。
# 字型不進 repo (.gitignore)，也不打包進 App，只給截圖測試排版中文用。
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p fonts
base=https://github.com/notofonts/noto-cjk/raw/main/Sans/SubsetOTF
for lang in TC SC; do
  for w in Regular Medium Bold; do
    f="fonts/NotoSans${lang}-${w}.otf"
    [ -s "$f" ] || curl -fsSL -o "$f" "$base/${lang}/NotoSans${lang}-${w}.otf"
  done
done
ls -l fonts
