import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'app_language.dart';
export 'generated/app_localizations.dart';

/// 畫面中取得翻譯字串：`context.l10n.appTitle`
extension AppL10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
