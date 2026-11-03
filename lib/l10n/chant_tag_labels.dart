import '../core/constants/chant_songs.dart';
import 'generated/app_localizations.dart';

/// 佛曲分類標籤的顯示文字
String chantTagLabel(AppLocalizations l10n, ChantTag tag) {
  switch (tag) {
    case ChantTag.fourCharAmitabha:
      return l10n.chantTagFourCharAmitabha;
    case ChantTag.sixCharAmitabha:
      return l10n.chantTagSixCharAmitabha;
    case ChantTag.bodhisattvaMantra:
      return l10n.chantTagBodhisattvaMantra;
    case ChantTag.pilgrimage:
      return l10n.chantTagPilgrimage;
    case ChantTag.lingyan:
      return l10n.chantTagLingyan;
    case ChantTag.masterChant:
      return l10n.chantTagMasterChant;
    case ChantTag.briskMedium:
      return l10n.chantTagBriskMedium;
    case ChantTag.slowSolemn:
      return l10n.chantTagSlowSolemn;
  }
}
