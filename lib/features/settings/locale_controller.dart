import 'package:flutter/widgets.dart';
import '../../core/constants/chant_songs.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/practice_record_service.dart';
import '../../core/services/storage_service.dart';
import '../../l10n/l10n.dart';

/// App 語言：依使用者偏好 ([AppLanguage]) 與手機語言解析出實際使用的 [locale]。
///
/// 沒有 BuildContext 的地方 (曲目名稱、通知、桌面小工具、背景播放的媒體資訊)
/// 由這裡在語言變更時統一推送新語言。
class LocaleController extends ChangeNotifier {
  LocaleController({
    required StorageService storage,
    required PracticeRecordService records,
    required NotificationService notifications,
    required AudioService audio,
    List<Locale>? deviceLocales,
  })  : _storage = storage,
        _records = records,
        _notifications = notifications,
        _audio = audio,
        _appLanguage = storage.getAppLanguage(),
        _deviceLocales = List.unmodifiable(deviceLocales ??
            WidgetsBinding.instance.platformDispatcher.locales) {
    _locale = resolveAppLocale(_deviceLocales, _appLanguage);
    _pushLocaleToServices();
  }

  final StorageService _storage;
  final PracticeRecordService _records;
  final NotificationService _notifications;
  final AudioService _audio;

  AppLanguage _appLanguage;
  AppLanguage get appLanguage => _appLanguage;

  List<Locale> _deviceLocales;

  late Locale _locale;

  /// 目前實際使用的語言 (已依偏好與手機語言解析)
  Locale get locale => _locale;

  void setAppLanguage(AppLanguage value) {
    _appLanguage = value;
    _storage.setAppLanguage(value);
    _resolve();
    notifyListeners();
  }

  /// 手機系統語言變更時呼叫 (WidgetsBindingObserver.didChangeLocales)
  void updateDeviceLocales(List<Locale> locales) {
    _deviceLocales = List.unmodifiable(locales);
    if (_resolve()) notifyListeners();
  }

  /// 重新解析語言；有變更時回傳 true
  bool _resolve() {
    final next = resolveAppLocale(_deviceLocales, _appLanguage);
    if (next == _locale) return false;
    _locale = next;
    _pushLocaleToServices();
    // 執行中切換語言：小工具文字與每日提醒立即換成新語言
    _records.syncWidget();
    _notifications.refreshDailyReminder();
    return true;
  }

  void _pushLocaleToServices() {
    ChantConstants.applyLocale(_locale);
    _records.locale = _locale;
    _notifications.locale = _locale;
    _audio.handler.refreshMediaItems(lookupAppLocalizations(_locale));
  }
}
