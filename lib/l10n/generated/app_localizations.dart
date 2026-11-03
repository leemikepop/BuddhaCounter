import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ];

  /// App 名稱 (視窗標題、關於頁)
  ///
  /// In zh, this message translates to:
  /// **'念佛計數器'**
  String get appTitle;

  /// 通用：取消按鈕
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// 通用：確認按鈕
  ///
  /// In zh, this message translates to:
  /// **'確認'**
  String get commonConfirm;

  /// 通用：套用自訂數值的按鈕
  ///
  /// In zh, this message translates to:
  /// **'設定'**
  String get commonSet;

  /// 通用：關閉按鈕 / tooltip
  ///
  /// In zh, this message translates to:
  /// **'關閉'**
  String get commonClose;

  /// 語言設定選單標題 (Drawer 項目、設定頁區塊、面板標題)
  ///
  /// In zh, this message translates to:
  /// **'語言'**
  String get languageMenuTitle;

  /// 語言選項：跟隨手機系統語言
  ///
  /// In zh, this message translates to:
  /// **'跟隨系統'**
  String get languageFollowSystem;

  /// 通用：開始 (計時、自動計數)
  ///
  /// In zh, this message translates to:
  /// **'開始'**
  String get commonStart;

  /// 通用：暫停
  ///
  /// In zh, this message translates to:
  /// **'暫停'**
  String get commonPause;

  /// 分頁名稱：手動計數 (底部分頁、標題列、側邊選單)
  ///
  /// In zh, this message translates to:
  /// **'手動計數'**
  String get tabManual;

  /// 分頁名稱：自動計數
  ///
  /// In zh, this message translates to:
  /// **'自動計數'**
  String get tabAuto;

  /// 分頁名稱：迴向 (迴向文頁)
  ///
  /// In zh, this message translates to:
  /// **'迴向'**
  String get tabDedication;

  /// 分頁名稱：功課月曆
  ///
  /// In zh, this message translates to:
  /// **'功課月曆'**
  String get tabCalendar;

  /// Toast：已切到淺色主題
  ///
  /// In zh, this message translates to:
  /// **'已切換為淺色模式'**
  String get themeSwitchedLightToast;

  /// Toast：已切到深色主題
  ///
  /// In zh, this message translates to:
  /// **'已切換為深色模式'**
  String get themeSwitchedDarkToast;

  /// Tooltip：切換到淺色主題
  ///
  /// In zh, this message translates to:
  /// **'切換為淺色模式'**
  String get themeToLightTooltip;

  /// Tooltip：切換到深色主題
  ///
  /// In zh, this message translates to:
  /// **'切換為深色模式'**
  String get themeToDarkTooltip;

  /// Tooltip：解除螢幕方向鎖定
  ///
  /// In zh, this message translates to:
  /// **'解除方向鎖定'**
  String get orientationUnlockTooltip;

  /// Tooltip：鎖定螢幕方向
  ///
  /// In zh, this message translates to:
  /// **'鎖定螢幕方向'**
  String get orientationLockTooltip;

  /// Toast：已鎖定方向
  ///
  /// In zh, this message translates to:
  /// **'已鎖定螢幕方向'**
  String get orientationLockedToast;

  /// Toast：已解除方向鎖定
  ///
  /// In zh, this message translates to:
  /// **'已解除方向鎖定'**
  String get orientationUnlockedToast;

  /// 螢幕常亮 (tooltip 與開啟時的 Toast)
  ///
  /// In zh, this message translates to:
  /// **'螢幕常亮'**
  String get screenAwakeOn;

  /// Tooltip：關閉螢幕常亮
  ///
  /// In zh, this message translates to:
  /// **'關閉螢幕常亮'**
  String get screenAwakeOffTooltip;

  /// Toast：已關閉螢幕常亮
  ///
  /// In zh, this message translates to:
  /// **'已關閉螢幕常亮'**
  String get screenAwakeOffToast;

  /// Tooltip / 側邊選單：切回經典模式
  ///
  /// In zh, this message translates to:
  /// **'切換回經典模式'**
  String get switchToClassicMode;

  /// Toast：已切到經典模式
  ///
  /// In zh, this message translates to:
  /// **'已切換為經典模式'**
  String get switchedToClassicToast;

  /// 側邊選單頂部大標題
  ///
  /// In zh, this message translates to:
  /// **'念佛、拜佛記數器'**
  String get drawerHeaderTitle;

  /// 側邊選單頂部副標 (佛號)
  ///
  /// In zh, this message translates to:
  /// **'南無阿彌陀佛'**
  String get drawerHeaderSubtitle;

  /// 側邊選單：開啟佛曲清單
  ///
  /// In zh, this message translates to:
  /// **'選擇佛曲清單'**
  String get drawerSongList;

  /// 側邊選單：開啟功能導覽
  ///
  /// In zh, this message translates to:
  /// **'新版功能導覽教學'**
  String get drawerGuide;

  /// 側邊選單：關於頁 (作者小站名稱)
  ///
  /// In zh, this message translates to:
  /// **'阿忠小站 · 緣起傳承'**
  String get drawerAbout;

  /// 手動計數歸零確認對話框標題
  ///
  /// In zh, this message translates to:
  /// **'確認要歸零嗎？'**
  String get counterResetConfirmTitle;

  /// 手動計數歸零確認對話框內文
  ///
  /// In zh, this message translates to:
  /// **'目前計數為{count}'**
  String counterResetConfirmBody(int count);

  /// 手動計數歸零確認按鈕
  ///
  /// In zh, this message translates to:
  /// **'確認歸零'**
  String get counterResetConfirmAction;

  /// Toast：手動計數已歸零
  ///
  /// In zh, this message translates to:
  /// **'已歸零'**
  String get counterResetDoneToast;

  /// 手動計數目標設定面板標題
  ///
  /// In zh, this message translates to:
  /// **'設定手動計數目標'**
  String get manualGoalSheetTitle;

  /// Tooltip：碼表重設
  ///
  /// In zh, this message translates to:
  /// **'重設計時'**
  String get timerResetTooltip;

  /// 目標小按鈕文字 (已設定目標)
  ///
  /// In zh, this message translates to:
  /// **'目標 {count}'**
  String goalChipLabel(int count);

  /// 目標小按鈕文字 (未設定目標)
  ///
  /// In zh, this message translates to:
  /// **'目標 不限'**
  String get goalChipUnlimited;

  /// 小按鈕：計數減一 (英文用符號以節省寬度)
  ///
  /// In zh, this message translates to:
  /// **'減一'**
  String get counterMinusOne;

  /// 手動計數小按鈕：歸零
  ///
  /// In zh, this message translates to:
  /// **'歸零'**
  String get counterResetShort;

  /// 手動計數頁：點擊音效選擇標題
  ///
  /// In zh, this message translates to:
  /// **'音效'**
  String get soundEffectTitle;

  /// 音效分段按鈕：木魚一 (極短)
  ///
  /// In zh, this message translates to:
  /// **'木魚1'**
  String get soundChipWoodfish1;

  /// 音效分段按鈕：木魚二 (極短)
  ///
  /// In zh, this message translates to:
  /// **'木魚2'**
  String get soundChipWoodfish2;

  /// 音效分段按鈕：引磬 (極短)
  ///
  /// In zh, this message translates to:
  /// **'引磬'**
  String get soundChipBell;

  /// 音效分段按鈕：靜音 (極短)
  ///
  /// In zh, this message translates to:
  /// **'靜音'**
  String get soundChipMute;

  /// 開關：點擊震動回饋
  ///
  /// In zh, this message translates to:
  /// **'震動回饋'**
  String get vibrationFeedback;

  /// 開關：全螢幕任意處點擊皆可計數
  ///
  /// In zh, this message translates to:
  /// **'全螢幕點擊'**
  String get fullscreenTap;

  /// 手動計數圓盤數字下方的單位
  ///
  /// In zh, this message translates to:
  /// **'聲 · 拜'**
  String get zenCircleUnitLabel;

  /// 圓盤內目標進度標籤
  ///
  /// In zh, this message translates to:
  /// **'目標 {count} · {percent}%'**
  String goalProgressLabel(int count, int percent);

  /// 圓盤內目標已達成標籤
  ///
  /// In zh, this message translates to:
  /// **'達成 {count} 聲'**
  String goalReachedLabel(int count);

  /// 目標選項：不限
  ///
  /// In zh, this message translates to:
  /// **'不限目標'**
  String get goalUnlimited;

  /// 目標選項：目前為自訂數值時顯示的晶片
  ///
  /// In zh, this message translates to:
  /// **'{value}(自訂)'**
  String goalCustomChip(int value);

  /// 目標面板自訂輸入提示
  ///
  /// In zh, this message translates to:
  /// **'或自訂目標聲數：'**
  String get goalCustomPrompt;

  /// 目標自訂輸入框 placeholder
  ///
  /// In zh, this message translates to:
  /// **'輸入目標 (如 500)'**
  String get goalCustomHint;

  /// 數字輸入框後綴：聲數單位
  ///
  /// In zh, this message translates to:
  /// **'聲'**
  String get unitRecitationsSuffix;

  /// 目標輸入無效時的提示
  ///
  /// In zh, this message translates to:
  /// **'請輸入大於 0 的有效目標數字'**
  String get goalInvalidNumber;

  /// Toast：目標改為不限
  ///
  /// In zh, this message translates to:
  /// **'已設定為不限目標'**
  String get goalSetUnlimitedToast;

  /// Toast：目標已設定
  ///
  /// In zh, this message translates to:
  /// **'已設定目標：{count} 聲'**
  String goalSetToast(int count);

  /// 自動計數：自動停止設定面板標題
  ///
  /// In zh, this message translates to:
  /// **'設定自動停止'**
  String get autoStopSheetTitle;

  /// 自動停止面板說明：聲數與時間互斥
  ///
  /// In zh, this message translates to:
  /// **'聲數與時間只能擇一，設定其中一項會清空另一項。'**
  String get autoStopExclusiveHint;

  /// 自動停止面板：依聲數區塊標題
  ///
  /// In zh, this message translates to:
  /// **'念滿聲數停止'**
  String get autoStopByCountTitle;

  /// 自動停止面板：依時間區塊標題
  ///
  /// In zh, this message translates to:
  /// **'定時停止'**
  String get autoStopByTimeTitle;

  /// 自動停止聲數選項晶片
  ///
  /// In zh, this message translates to:
  /// **'{count} 聲'**
  String autoCountChip(int count);

  /// 自動停止聲數：目前為自訂值的晶片
  ///
  /// In zh, this message translates to:
  /// **'{count} 聲 (自訂)'**
  String autoCountCustomChip(int count);

  /// Toast：已設定聲數自動停止
  ///
  /// In zh, this message translates to:
  /// **'已設定念滿 {count} 聲自動停止'**
  String autoCountGoalSetToast(int count);

  /// Toast：取消聲數自動停止
  ///
  /// In zh, this message translates to:
  /// **'已取消聲數目標，持續播放'**
  String get autoCountGoalClearedToast;

  /// 定時停止分鐘選項晶片
  ///
  /// In zh, this message translates to:
  /// **'{minutes} 分鐘'**
  String autoMinutesChip(int minutes);

  /// 定時停止：目前為自訂值的晶片
  ///
  /// In zh, this message translates to:
  /// **'{minutes} 分鐘 (自訂)'**
  String autoMinutesCustomChip(int minutes);

  /// 定時停止自訂輸入提示
  ///
  /// In zh, this message translates to:
  /// **'或自訂分鐘數：'**
  String get autoMinutesPrompt;

  /// 定時停止輸入框 placeholder
  ///
  /// In zh, this message translates to:
  /// **'輸入分鐘數 (如 20)'**
  String get autoMinutesHint;

  /// 數字輸入框後綴：分鐘
  ///
  /// In zh, this message translates to:
  /// **'分鐘'**
  String get unitMinutesSuffix;

  /// 定時停止輸入無效提示
  ///
  /// In zh, this message translates to:
  /// **'請輸入大於 0 的有效分鐘數'**
  String get autoMinutesInvalid;

  /// Toast：已設定定時停止
  ///
  /// In zh, this message translates to:
  /// **'已設定定時停止：{minutes} 分鐘'**
  String autoTimerSetToast(int minutes);

  /// Toast：取消定時停止
  ///
  /// In zh, this message translates to:
  /// **'已取消定時停止，持續播放'**
  String get autoTimerClearedToast;

  /// 自動停止面板：清除兩種停止條件按鈕
  ///
  /// In zh, this message translates to:
  /// **'清除設定，持續播放'**
  String get autoStopClearAction;

  /// Toast：已清除自動停止
  ///
  /// In zh, this message translates to:
  /// **'已清除設定，持續播放'**
  String get autoStopClearedToast;

  /// Toast：自動計數已經是 0
  ///
  /// In zh, this message translates to:
  /// **'目前計數已為 0'**
  String get autoAlreadyZeroToast;

  /// 自動計數重置確認對話框標題
  ///
  /// In zh, this message translates to:
  /// **'重設自動計數？'**
  String get autoResetConfirmTitle;

  /// 自動計數重置確認對話框內文
  ///
  /// In zh, this message translates to:
  /// **'目前自動計數為 {count} 聲，確定要歸零重置嗎？\n（計時時間將會保留）'**
  String autoResetConfirmBody(int count);

  /// 自動計數重置確認按鈕
  ///
  /// In zh, this message translates to:
  /// **'確認重置'**
  String get autoResetConfirmAction;

  /// Toast：自動計數已重置
  ///
  /// In zh, this message translates to:
  /// **'自動計數已重置為 0'**
  String get autoResetDoneToast;

  /// Toast：自動計數碼表已重置
  ///
  /// In zh, this message translates to:
  /// **'計時已重置'**
  String get autoTimerResetToast;

  /// 圓盤內定時停止進度；remaining 為已格式化的剩餘時間
  ///
  /// In zh, this message translates to:
  /// **'定時 {minutes} 分 · 剩 {remaining}'**
  String autoTimeProgressLabel(int minutes, String remaining);

  /// 圓盤內定時已到
  ///
  /// In zh, this message translates to:
  /// **'定時 {minutes} 分 · 已到'**
  String autoTimeReachedLabel(int minutes);

  /// 自動停止小按鈕：目前為定時停止
  ///
  /// In zh, this message translates to:
  /// **'定時 {minutes} 分'**
  String autoTimerChip(int minutes);

  /// 自動停止小按鈕：未設定任何停止條件
  ///
  /// In zh, this message translates to:
  /// **'持續播放'**
  String get autoContinuous;

  /// 自動計數圓盤數字下方單位
  ///
  /// In zh, this message translates to:
  /// **'聲 · 遍'**
  String get autoCircleUnitLabel;

  /// 自動計數圓盤：每拍秒數；seconds 為小數兩位字串
  ///
  /// In zh, this message translates to:
  /// **'每拍 {seconds}s 自動累加'**
  String autoBeatHint(String seconds);

  /// 自動計數小按鈕：重置計數
  ///
  /// In zh, this message translates to:
  /// **'重置'**
  String get autoResetShort;

  /// 剩餘時間 (分鐘)
  ///
  /// In zh, this message translates to:
  /// **'{minutes} 分'**
  String autoRemainingMinutes(int minutes);

  /// 剩餘時間 (秒)
  ///
  /// In zh, this message translates to:
  /// **'{seconds} 秒'**
  String autoRemainingSeconds(int seconds);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
