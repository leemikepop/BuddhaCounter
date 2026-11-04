import 'package:flutter/services.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/storage_service.dart';
import 'settings_controller.dart';

/// 點擊回饋：依使用者設定播放敲擊音效並震動
class TapFeedback {
  TapFeedback(this._audio, this._settings);

  final AudioService _audio;
  final SettingsController _settings;

  /// 計數一聲：敲擊音效 + 輕震
  void count() {
    _audio.playClickSfx(_settings.soundEffect);
    if (_settings.vibrationEnabled) HapticFeedback.lightImpact();
  }

  /// 減一等次要操作：只有輕微震動
  void tick() {
    if (_settings.vibrationEnabled) HapticFeedback.selectionClick();
  }

  /// 只播放目前設定的敲擊音效 (不震動)
  void sound() => _audio.playClickSfx(_settings.soundEffect);

  /// 試聽指定音效 (設定頁選擇音效、迴向頁敲引磬)
  void preview(SoundEffectType type) => _audio.playClickSfx(type);
}
