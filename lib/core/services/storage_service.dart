import 'package:shared_preferences/shared_preferences.dart';

enum SoundEffectType {
  bell,     // 引磬 (ens.mp3)
  woodfish, // 木魚 (mus.mp3)
  none,     // 靜音
}

enum AppUiMode {
  legacy, // 經典復古模式（父親原創介面）
  modern, // 現代禪意模式
}

class StorageService {
  static const String keyCounter = 'pref_counter';
  static const String keySoundEffect = 'pref_sound_effect';
  static const String keyUiMode = 'pref_ui_mode';
  static const String keyKeepScreenOnHome = 'DormancyCB1';
  static const String keyKeepScreenOnChant = 'DormancyCB2';
  static const String keyKeepScreenOnSongs = 'DormancyCB3';
  static const String keyKeepScreenOnAuto = 'DormancyCB4';
  static const String keyLastSongId = 'pref_last_song_id';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  int getCounter() => _prefs.getInt(keyCounter) ?? 0;
  Future<void> setCounter(int val) => _prefs.setInt(keyCounter, val);

  SoundEffectType getSoundEffect() {
    final index = _prefs.getInt(keySoundEffect) ?? SoundEffectType.woodfish.index;
    if (index >= 0 && index < SoundEffectType.values.length) {
      return SoundEffectType.values[index];
    }
    return SoundEffectType.woodfish;
  }
  Future<void> setSoundEffect(SoundEffectType type) =>
      _prefs.setInt(keySoundEffect, type.index);

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

  int getLastSongId() => _prefs.getInt(keyLastSongId) ?? 1;
  Future<void> setLastSongId(int id) => _prefs.setInt(keyLastSongId, id);
}
