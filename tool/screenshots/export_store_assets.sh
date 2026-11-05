#!/usr/bin/env bash
# 把產生好的宣傳圖複製到 assets/store_assets/ (要上傳商店、放進 repo 的版本)。
#   flutter test tool/screenshots                    # 先產生
#   bash tool/screenshots/export_store_assets.sh     # 預設繁中；其他語言：zh_Hans / en
set -euo pipefail
cd "$(dirname "$0")/../.."
loc=${1:-zh_Hant}
src=build/screenshots/posters
dst=assets/store_assets
if [ ! -d "$src/iphone_6.9/$loc" ]; then
  echo "找不到 $src/iphone_6.9/$loc，請先執行 flutter test tool/screenshots" >&2
  exit 1
fi
copy() { # <來源裝置> <目的資料夾>
  rm -rf "$dst/$2/$loc"
  mkdir -p "$dst/$2/$loc"
  cp "$src/$1/$loc/"*.jpg "$dst/$2/$loc/"
}
copy iphone_6.9 app_store/iphone_6.9
copy ipad_13 app_store/ipad_13
copy android_phone google_play/phone
if [ "$loc" = zh_Hant ]; then
  cp "$src/github_social_preview.png" "$dst/github_social_preview_1280x640.png"
  cp "$src/readme_banner.png" "$dst/readme_banner.png"
fi
find "$dst" -newer "$0" -type f | sort
