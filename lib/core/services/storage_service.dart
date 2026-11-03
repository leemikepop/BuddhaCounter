import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_language.dart';

enum SoundEffectType {
  woodfish1, // 木魚一 (wooden-fish-1.mp3)
  woodfish2, // 木魚二 (wooden-fish-3.mp3，原 mus.mp3 經典原音)
  bell, // 引磬 (ens.mp3)
  none; // 靜音

  /// 取得對應音效檔路徑 (若為 none 則為 null)
  String? get assetPath {
    switch (this) {
      case SoundEffectType.woodfish1:
        return 'audio/wooden-fish-1.mp3';
      case SoundEffectType.woodfish2:
        return 'audio/wooden-fish-2.mp3';
      case SoundEffectType.bell:
        return 'audio/ens.mp3';
      case SoundEffectType.none:
        return null;
    }
  }

  /// 介面顯示名稱
  String get displayName {
    switch (this) {
      case SoundEffectType.woodfish1:
        return '木魚一';
      case SoundEffectType.woodfish2:
        return '木魚二';
      case SoundEffectType.bell:
        return '引磬';
      case SoundEffectType.none:
        return '靜音';
    }
  }
}

enum AppUiMode {
  legacy, // 經典復古模式
  modern, // 現代禪意模式
}

class StorageService {
  static const String keyCounter = 'pref_counter';
  static const String keySoundEffect = 'pref_sound_effect';
  static const String keySoundEffectKey = 'pref_sound_effect_key';
  static const String keyUiMode = 'pref_ui_mode';
  static const String keyKeepScreenOnHome = 'DormancyCB1';
  static const String keyKeepScreenOnChant = 'DormancyCB2';
  static const String keyKeepScreenOnSongs = 'DormancyCB3';
  static const String keyKeepScreenOnAuto = 'DormancyCB4';
  static const String keyLastSongId = 'pref_last_song_id';
  static const String keyAutoCounter = 'autoCounter';
  static const String keyAutoElapsedSeconds = 'autoTsec';
  static const String keyAutoStopMinutes = 'stopTime';
  static const String keyThemeMode = 'pref_theme_mode';
  static const String keyVibrationEnabled = 'pref_vibration_enabled';
  static const String keyTargetCount = 'pref_target_count';
  static const String keyAutoTargetCount = 'pref_auto_target_count';
  static const String keyDailyTargetCount = 'pref_daily_target_count';
  static const String keyFullscreenTap = 'pref_fullscreen_tap';
  static const String keyOrientationLocked = 'pref_orientation_locked';
  static const String keySeenModernGuide = 'pref_seen_modern_guide';
  static const String keyHuiXiangIndex = 'pref_hui_xiang_index';
  static const String keyDailyRecords = 'pref_daily_records';
  static const String keyReminderEnabled = 'pref_reminder_enabled';
  static const String keyReminderHour = 'pref_reminder_hour';
  static const String keyReminderMinute = 'pref_reminder_minute';
  static const String keyLastActiveDate = 'pref_last_active_date';
  static const String keyAppLanguage = 'pref_locale';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  int getCounter() => _prefs.getInt(keyCounter) ?? 0;
  Future<void> setCounter(int val) => _prefs.setInt(keyCounter, val);

  SoundEffectType getSoundEffect() {
    final key = _prefs.getString(keySoundEffectKey);
    if (key != null) {
      for (final type in SoundEffectType.values) {
        if (type.name == key) return type;
      }
    }
    final index = _prefs.getInt(keySoundEffect);
    if (index != null) {
      // 舊版相容對照：0: bell, 1: 原版木魚 (對應木魚二), 2: none
      if (index == 0) return SoundEffectType.bell;
      if (index == 1) return SoundEffectType.woodfish2;
      if (index == 2) return SoundEffectType.none;
      if (index >= 0 && index < SoundEffectType.values.length) {
        return SoundEffectType.values[index];
      }
    }
    return SoundEffectType.woodfish1;
  }

  Future<void> setSoundEffect(SoundEffectType type) async {
    await _prefs.setInt(keySoundEffect, type.index);
    await _prefs.setString(keySoundEffectKey, type.name);
  }

  AppUiMode getUiMode() {
    final val = _prefs.getString(keyUiMode);
    if (val == 'modern') return AppUiMode.modern;
    return AppUiMode.legacy; // 預設為經典模式
  }

  Future<void> setUiMode(AppUiMode mode) =>
      _prefs.setString(keyUiMode, mode.name);

  bool getKeepScreenOnHome() => _prefs.getBool(keyKeepScreenOnHome) ?? false;
  Future<void> setKeepScreenOnHome(bool val) =>
      _prefs.setBool(keyKeepScreenOnHome, val);

  bool getKeepScreenOnChant() => _prefs.getBool(keyKeepScreenOnChant) ?? false;
  Future<void> setKeepScreenOnChant(bool val) =>
      _prefs.setBool(keyKeepScreenOnChant, val);

  bool getKeepScreenOnSongs() => _prefs.getBool(keyKeepScreenOnSongs) ?? false;
  Future<void> setKeepScreenOnSongs(bool val) =>
      _prefs.setBool(keyKeepScreenOnSongs, val);

  bool getKeepScreenOnAuto() => _prefs.getBool(keyKeepScreenOnAuto) ?? false;
  Future<void> setKeepScreenOnAuto(bool val) =>
      _prefs.setBool(keyKeepScreenOnAuto, val);

  int getLastSongId() => _prefs.getInt(keyLastSongId) ?? 0;
  Future<void> setLastSongId(int id) => _prefs.setInt(keyLastSongId, id);

  int getAutoCounter() => _prefs.getInt(keyAutoCounter) ?? 0;
  Future<void> setAutoCounter(int val) => _prefs.setInt(keyAutoCounter, val);

  int getAutoElapsedSeconds() => _prefs.getInt(keyAutoElapsedSeconds) ?? 0;
  Future<void> setAutoElapsedSeconds(int val) =>
      _prefs.setInt(keyAutoElapsedSeconds, val);

  int getAutoStopMinutes() => _prefs.getInt(keyAutoStopMinutes) ?? 0;
  Future<void> setAutoStopMinutes(int val) =>
      _prefs.setInt(keyAutoStopMinutes, val);

  String getThemeMode() => _prefs.getString(keyThemeMode) ?? 'light';
  Future<void> setThemeMode(String mode) =>
      _prefs.setString(keyThemeMode, mode);

  bool getVibrationEnabled() => _prefs.getBool(keyVibrationEnabled) ?? true;
  Future<void> setVibrationEnabled(bool val) =>
      _prefs.setBool(keyVibrationEnabled, val);

  /// 手動計數目標聲數 (0 = 不限)
  int getTargetCount() => _prefs.getInt(keyTargetCount) ?? 108;
  Future<void> setTargetCount(int val) => _prefs.setInt(keyTargetCount, val);

  /// 自動計數目標聲數 (0 = 不限)：念滿即自動停止，與定時停止 [getAutoStopMinutes] 互斥
  int getAutoTargetCount() => _prefs.getInt(keyAutoTargetCount) ?? 0;
  Future<void> setAutoTargetCount(int val) =>
      _prefs.setInt(keyAutoTargetCount, val);

  /// 每日功課目標聲數 (0 = 不限)，比較對象為當日手動 + 自動總聲數
  /// 舊版升級時尚無獨立設定，首次讀取即沿用原手動目標並寫回，之後兩者各自獨立
  int getDailyTargetCount() {
    final stored = _prefs.getInt(keyDailyTargetCount);
    if (stored != null) return stored;
    final inherited = getTargetCount();
    _prefs.setInt(keyDailyTargetCount, inherited);
    return inherited;
  }

  Future<void> setDailyTargetCount(int val) =>
      _prefs.setInt(keyDailyTargetCount, val);

  bool getFullscreenTap() => _prefs.getBool(keyFullscreenTap) ?? false;
  Future<void> setFullscreenTap(bool val) =>
      _prefs.setBool(keyFullscreenTap, val);

  bool getOrientationLocked() => _prefs.getBool(keyOrientationLocked) ?? false;
  Future<void> setOrientationLocked(bool val) =>
      _prefs.setBool(keyOrientationLocked, val);

  bool getSeenModernGuide() => _prefs.getBool(keySeenModernGuide) ?? false;
  Future<void> setSeenModernGuide(bool val) =>
      _prefs.setBool(keySeenModernGuide, val);

  int getHuiXiangIndex() => _prefs.getInt(keyHuiXiangIndex) ?? 0;
  Future<void> setHuiXiangIndex(int val) =>
      _prefs.setInt(keyHuiXiangIndex, val);

  String? getDailyRecordsJson() => _prefs.getString(keyDailyRecords);
  Future<void> setDailyRecordsJson(String json) =>
      _prefs.setString(keyDailyRecords, json);

  bool getReminderEnabled() => _prefs.getBool(keyReminderEnabled) ?? false;
  Future<void> setReminderEnabled(bool val) =>
      _prefs.setBool(keyReminderEnabled, val);

  int getReminderHour() => _prefs.getInt(keyReminderHour) ?? 12;
  Future<void> setReminderHour(int hour) =>
      _prefs.setInt(keyReminderHour, hour);

  int getReminderMinute() => _prefs.getInt(keyReminderMinute) ?? 0;
  Future<void> setReminderMinute(int min) =>
      _prefs.setInt(keyReminderMinute, min);

  /// App 內語言偏好 (預設跟隨系統)
  AppLanguage getAppLanguage() =>
      AppLanguage.fromStorage(_prefs.getString(keyAppLanguage));
  Future<void> setAppLanguage(AppLanguage v) =>
      _prefs.setString(keyAppLanguage, v.storageValue);

  String getLastActiveDate() => _prefs.getString(keyLastActiveDate) ?? '';
  Future<void> setLastActiveDate(String dateStr) =>
      _prefs.setString(keyLastActiveDate, dateStr);
}
