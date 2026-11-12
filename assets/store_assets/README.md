# 商店素材

除了 `source/` 與 `google_play/feature_graphic_1024x500.png`，這裡的圖都是程式產生的，**不要手動修改**：
改了畫面就重新產生（見 [開發指南](../../docs/DEVELOPMENT.md#商店截圖與宣傳圖)）。

```bash
bash tool/screenshots/fetch_fonts.sh             # 第一次：下載字型
flutter test tool/screenshots                    # 產生到 build/screenshots/
bash tool/screenshots/export_store_assets.sh     # 繁中宣傳圖複製到這裡 (其他語言：zh_Hans / en)
```

也可以在 GitHub Actions 手動執行 **Screenshots - Generate store images**，下載 `store-assets` 解壓縮到這個資料夾。

| 路徑 | 用途 | 尺寸 |
|---|---|---|
| `app_store/iphone_6.9/<語言>/` | App Store iPhone 6.9 吋截圖 | 1320×2868 |
| `app_store/ipad_13/<語言>/` | App Store iPad 13 吋截圖 | 2064×2752 |
| `google_play/phone/<語言>/` | Google Play 手機截圖 | 1080×1920 |
| `google_play/feature_graphic_1024x500.png` | Google Play 主要宣傳圖（手工製作） | 1024×500 |
| `github_social_preview_1280x640.png` | GitHub 社群預覽圖（Settings → Social preview 手動上傳） | 1280×640 |
| `readme_banner.png` | README 首圖 | 2160×960 |
| `source/paper_template_1080x1920.png` | 宣傳圖的紙紋背景（裡面的手機會被程式畫的外框蓋住） | 1080×1920 |
| `source/paper_art_3840x2143.png` | GitHub 社群預覽圖的背景 | 3840×2143 |

每張宣傳圖的標題與副標寫在 `tool/screenshots/posters.dart` 的 `_captions`。
repo 裡只放繁中；簡中、英文要用時再產生。不加文字的原始截圖在 `build/screenshots/<裝置>/<語言>/`。
