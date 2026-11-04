import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/constants/chant_songs.dart';
import '../../core/services/storage_service.dart';

/// 使用者偏好設定：介面模式、主題、音效、震動、螢幕常亮、螢幕方向、迴向文頁。
/// 每次變更都會立即寫入 [StorageService]。
class SettingsController extends ChangeNotifier {
  SettingsController(this._storage)
      : _soundEffect = _storage.getSoundEffect(),
        _uiMode = _storage.getUiMode(),
        _themeMode = _themeModeFromStorage(_storage.getThemeMode()),
        _vibrationEnabled = _storage.getVibrationEnabled(),
        _fullscreenTap = _storage.getFullscreenTap(),
        _keepScreenOn = _storage.getKeepScreenOn(),
        _isOrientationLocked = _storage.getOrientationLocked(),
        _hasSeenModernGuide = _storage.getSeenModernGuide(),
        _huiXiangIndex = _storage
            .getHuiXiangIndex()
            .clamp(0, ChantConstants.huiXiangCount - 1) {
    if (_isOrientationLocked) _applyOrientationLock();
  }

  final StorageService _storage;

  SoundEffectType _soundEffect;
  SoundEffectType get soundEffect => _soundEffect;

  AppUiMode _uiMode;
  AppUiMode get uiMode => _uiMode;

  ThemeMode _themeMode;
  ThemeMode get themeMode => _themeMode;

  bool _vibrationEnabled;
  bool get vibrationEnabled => _vibrationEnabled;

  /// 現代模式：點擊計數頁任何位置都算一聲
  bool _fullscreenTap;
  bool get fullscreenTap => _fullscreenTap;

  bool _keepScreenOn;
  bool get keepScreenOn => _keepScreenOn;

  bool _isOrientationLocked;
  bool get isOrientationLocked => _isOrientationLocked;

  bool _hasSeenModernGuide;
  bool get hasSeenModernGuide => _hasSeenModernGuide;

  /// 迴向頁目前顯示第幾篇迴向文
  int _huiXiangIndex;
  int get huiXiangIndex => _huiXiangIndex;

  void setSoundEffect(SoundEffectType type) {
    _soundEffect = type;
    _storage.setSoundEffect(type);
    notifyListeners();
  }

  void setUiMode(AppUiMode mode) {
    _uiMode = mode;
    _storage.setUiMode(mode);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _storage.setThemeMode(mode.name);
    notifyListeners();
  }

  void setVibrationEnabled(bool value) {
    _vibrationEnabled = value;
    _storage.setVibrationEnabled(value);
    notifyListeners();
  }

  void setFullscreenTap(bool value) {
    _fullscreenTap = value;
    _storage.setFullscreenTap(value);
    notifyListeners();
  }

  Future<void> markModernGuideSeen() async {
    _hasSeenModernGuide = true;
    await _storage.setSeenModernGuide(true);
    notifyListeners();
  }

  Future<void> setHuiXiangIndex(int index) async {
    final clamped = index.clamp(0, ChantConstants.huiXiangCount - 1);
    if (_huiXiangIndex == clamped) return;
    _huiXiangIndex = clamped;
    await _storage.setHuiXiangIndex(clamped);
    notifyListeners();
  }

  // --- 螢幕常亮 ---

  void setKeepScreenOn(bool value) {
    _keepScreenOn = value;
    _storage.setKeepScreenOn(value);
    _setWakelock(value);
    notifyListeners();
  }

  void toggleKeepScreenOn() => setKeepScreenOn(!_keepScreenOn);

  /// 進入頁面時套用螢幕常亮；[allowed] 為 false 的頁面 (功課月曆) 一律允許休眠
  void applyWakelock({bool allowed = true}) =>
      _setWakelock(allowed && _keepScreenOn);

  static void _setWakelock(bool enable) {
    try {
      (enable ? WakelockPlus.enable() : WakelockPlus.disable())
          .catchError((_) {});
    } catch (_) {}
  }

  // --- 螢幕方向鎖定 ---

  /// 切換方向鎖定；鎖定時固定在 [current] 的方向 (預設直向)
  void toggleOrientationLock([Orientation? current]) =>
      setOrientationLocked(!_isOrientationLocked, current);

  void setOrientationLocked(bool value, [Orientation? current]) {
    if (_isOrientationLocked == value) return;
    _isOrientationLocked = value;
    _storage.setOrientationLocked(value);
    _applyOrientationLock(current);
    notifyListeners();
  }

  void _applyOrientationLock([Orientation? current]) {
    const portrait = [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown
    ];
    const landscape = [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ];
    final orientations = !_isOrientationLocked
        ? [...portrait, ...landscape]
        : (current == Orientation.landscape ? landscape : portrait);
    try {
      SystemChrome.setPreferredOrientations(orientations);
    } catch (_) {}
  }

  static ThemeMode _themeModeFromStorage(String value) => switch (value) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      };
}
