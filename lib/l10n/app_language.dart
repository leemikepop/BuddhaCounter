import 'dart:ui';

/// 繁體中文 (台灣、香港、澳門)
const Locale kZhHant =
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');

/// 簡體中文 (馬來西亞、新加坡、中國)
const Locale kZhHans =
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');

/// 英文 (其他所有地區)
const Locale kEn = Locale('en');

/// App 內語言偏好 (存於 StorageService `pref_locale`)
enum AppLanguage {
  system('system'),
  zhHant('zh_Hant'),
  zhHans('zh_Hans'),
  en('en');

  const AppLanguage(this.storageValue);

  final String storageValue;

  /// 未知或空值一律視為「跟隨系統」
  static AppLanguage fromStorage(String? value) {
    for (final v in values) {
      if (v.storageValue == value) return v;
    }
    return AppLanguage.system;
  }
}

const _traditionalRegions = {'TW', 'HK', 'MO'};

/// 單一手機語言對應到 App 語言；不支援時回傳 null
Locale? _matchDeviceLocale(Locale device) {
  switch (device.languageCode) {
    case 'zh':
      final script = device.scriptCode;
      if (script == 'Hant') return kZhHant;
      if (script == 'Hans') return kZhHans;
      if (_traditionalRegions.contains(device.countryCode)) return kZhHant;
      return kZhHans;
    case 'en':
      return kEn;
    default:
      return null;
  }
}

/// 解析 App 實際使用的語言：
/// - 手動偏好優先
/// - 跟隨系統時依手機語言清單「順序」取第一個支援的語言，皆不支援則回退英文
Locale resolveAppLocale(List<Locale> deviceLocales, AppLanguage preference) {
  switch (preference) {
    case AppLanguage.zhHant:
      return kZhHant;
    case AppLanguage.zhHans:
      return kZhHans;
    case AppLanguage.en:
      return kEn;
    case AppLanguage.system:
      for (final d in deviceLocales) {
        final matched = _matchDeviceLocale(d);
        if (matched != null) return matched;
      }
      return kEn;
  }
}
