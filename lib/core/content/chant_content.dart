import 'dart:ui';

import 'chant_content_en.dart';
import 'chant_content_zh_hans.dart';
import 'chant_content_zh_hant.dart';

/// 一則迴向文 (標題 + 偈句)
class HuiXiangItem {
  final String title;
  final List<String> verses;

  const HuiXiangItem({
    required this.title,
    required this.verses,
  });
}

/// 曲目與經文內容目錄 (與介面字串分開管理)
///
/// - [songTitles]：依曲目 id 的曲名；繁中目錄為空 (沿用音檔 metadata 與程式碼常數)
/// - [artistNames]：以「繁中演出者名稱」為 key 的翻譯 (演出者來自音檔 metadata)
abstract class ChantContent {
  const ChantContent();

  Map<int, String> get songTitles;
  Map<String, String> get artistNames;
  String get defaultArtist;
  String get defaultAlbum;
  List<HuiXiangItem> get huiXiangItems;
}

/// 依語言取得內容目錄：zh + Hans → 簡中；其他 zh → 繁中；其餘 → 英文
ChantContent chantContentFor(Locale locale) {
  if (locale.languageCode == 'zh') {
    return locale.scriptCode == 'Hans'
        ? const ChantContentZhHans()
        : const ChantContentZhHant();
  }
  return const ChantContentEn();
}
