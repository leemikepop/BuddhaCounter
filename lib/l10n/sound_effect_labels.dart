import '../core/services/storage_service.dart';
import 'generated/app_localizations.dart';

/// 點擊音效的完整顯示名稱 (設定頁用；手動計數頁的極短按鈕另用 soundChip* 字串)
String soundEffectLabel(AppLocalizations l10n, SoundEffectType type) {
  switch (type) {
    case SoundEffectType.woodfish1:
      return l10n.soundWoodfish1;
    case SoundEffectType.woodfish2:
      return l10n.soundWoodfish2;
    case SoundEffectType.bell:
      return l10n.soundBell;
    case SoundEffectType.none:
      return l10n.soundMute;
  }
}
