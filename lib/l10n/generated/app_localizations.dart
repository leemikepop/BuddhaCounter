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

  /// Tooltip：年月選擇器上一年
  ///
  /// In zh, this message translates to:
  /// **'上一年'**
  String get calendarPrevYear;

  /// Tooltip：年月選擇器下一年
  ///
  /// In zh, this message translates to:
  /// **'下一年'**
  String get calendarNextYear;

  /// 年份顯示
  ///
  /// In zh, this message translates to:
  /// **'{year} 年'**
  String calendarYearLabel(int year);

  /// 年月選擇器月份格；monthShort 為英文月份縮寫，中文不使用
  ///
  /// In zh, this message translates to:
  /// **'{month} 月'**
  String calendarMonthChip(int month, String monthShort);

  /// 年月選擇器：回到本月
  ///
  /// In zh, this message translates to:
  /// **'回到本月'**
  String get calendarBackToThisMonth;

  /// 修改當日聲數對話框標題
  ///
  /// In zh, this message translates to:
  /// **'手動修改功課聲數'**
  String get calendarEditTitle;

  /// 修改對話框內的日期；monthName 為英文月份，中文不使用
  ///
  /// In zh, this message translates to:
  /// **'日期：{year}年{month}月{day}日'**
  String calendarEditDateLabel(int year, int month, int day, String monthName);

  /// 修改對話框輸入框 label
  ///
  /// In zh, this message translates to:
  /// **'今日功課聲數'**
  String get calendarEditFieldLabel;

  /// 修改對話框輸入框 placeholder
  ///
  /// In zh, this message translates to:
  /// **'請輸入念佛聲數'**
  String get calendarEditFieldHint;

  /// 修改對話框儲存按鈕
  ///
  /// In zh, this message translates to:
  /// **'確認儲存'**
  String get calendarEditSave;

  /// Toast：已更新當日聲數
  ///
  /// In zh, this message translates to:
  /// **'已更新功課紀錄為 {count} 聲'**
  String calendarEditSavedToast(int count);

  /// 提醒時間選擇器標題
  ///
  /// In zh, this message translates to:
  /// **'選擇每日念佛提醒時間'**
  String get reminderPickerHelp;

  /// Toast：已設定提醒時間；time 為 HH:mm
  ///
  /// In zh, this message translates to:
  /// **'已設定每日 {time} 定時提醒'**
  String reminderSetToast(String time);

  /// 月曆頂部連續天數
  ///
  /// In zh, this message translates to:
  /// **'連續精進 {days} 天'**
  String streakBanner(int days);

  /// 連續 7 天以上的小徽章
  ///
  /// In zh, this message translates to:
  /// **'精進不懈'**
  String get streakBadge;

  /// 已有連續天數時的鼓勵語
  ///
  /// In zh, this message translates to:
  /// **'念念相續，功德無量！繼續保持今日精進。'**
  String get streakEncourageActive;

  /// 尚無連續天數時的鼓勵語
  ///
  /// In zh, this message translates to:
  /// **'今日開啟第一聲佛號，建立每日精進習慣！'**
  String get streakEncourageStart;

  /// 統計卡：今日功課
  ///
  /// In zh, this message translates to:
  /// **'今日功課'**
  String get metricToday;

  /// 統計卡：本週累計
  ///
  /// In zh, this message translates to:
  /// **'本週累計'**
  String get metricWeek;

  /// 統計卡：本月累計
  ///
  /// In zh, this message translates to:
  /// **'本月累計'**
  String get metricMonth;

  /// 統計卡今日：每日目標與進度
  ///
  /// In zh, this message translates to:
  /// **'目標 {goal} ({percent}%)'**
  String metricTodayGoal(int goal, int percent);

  /// 統計卡今日：未設定每日目標
  ///
  /// In zh, this message translates to:
  /// **'無目標'**
  String get metricNoGoal;

  /// 統計卡本週副標
  ///
  /// In zh, this message translates to:
  /// **'週一至週日'**
  String get metricWeekSubtitle;

  /// 統計卡本月副標；monthShort 為英文月份縮寫
  ///
  /// In zh, this message translates to:
  /// **'{month}月總和'**
  String metricMonthSubtitle(int month, String monthShort);

  /// 一萬以上的精簡數字；tenThousands = n/10000、thousands = n/1000 (皆一位小數)
  ///
  /// In zh, this message translates to:
  /// **'{tenThousands}萬'**
  String compactNumber(String tenThousands, String thousands);

  /// 統計卡數值旁的單位 (英文留空)
  ///
  /// In zh, this message translates to:
  /// **'聲'**
  String get metricUnit;

  /// Tooltip：上一個月
  ///
  /// In zh, this message translates to:
  /// **'上一月'**
  String get calendarPrevMonth;

  /// Tooltip：下一個月
  ///
  /// In zh, this message translates to:
  /// **'下一月'**
  String get calendarNextMonth;

  /// 月曆標頭；monthName 為英文月份全名
  ///
  /// In zh, this message translates to:
  /// **'{year} 年 {month} 月'**
  String calendarMonthTitle(int year, int month, String monthName);

  /// 月曆：跳回今天按鈕
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get calendarToday;

  /// 星期列：星期日
  ///
  /// In zh, this message translates to:
  /// **'日'**
  String get weekdaySun;

  /// 星期列：星期一
  ///
  /// In zh, this message translates to:
  /// **'一'**
  String get weekdayMon;

  /// 星期列：星期二
  ///
  /// In zh, this message translates to:
  /// **'二'**
  String get weekdayTue;

  /// 星期列：星期三
  ///
  /// In zh, this message translates to:
  /// **'三'**
  String get weekdayWed;

  /// 星期列：星期四
  ///
  /// In zh, this message translates to:
  /// **'四'**
  String get weekdayThu;

  /// 星期列：星期五
  ///
  /// In zh, this message translates to:
  /// **'五'**
  String get weekdayFri;

  /// 星期列：星期六
  ///
  /// In zh, this message translates to:
  /// **'六'**
  String get weekdaySat;

  /// 選中日期卡片標題
  ///
  /// In zh, this message translates to:
  /// **'{year} 年 {month} 月 {day} 日'**
  String calendarSelectedDate(int year, int month, int day, String monthName);

  /// 選中日期為今天的小徽章
  ///
  /// In zh, this message translates to:
  /// **'今日'**
  String get calendarTodayBadge;

  /// 選中日期卡片：修改聲數按鈕
  ///
  /// In zh, this message translates to:
  /// **'修改數值'**
  String get calendarEditButton;

  /// 選中日期聲數後的單位
  ///
  /// In zh, this message translates to:
  /// **'聲佛號'**
  String get calendarCountUnit;

  /// 選中日期手動 / 自動明細
  ///
  /// In zh, this message translates to:
  /// **'手動: {manual} · 自動: {auto}'**
  String calendarBreakdown(int manual, int auto);

  /// 選中日期已達每日目標
  ///
  /// In zh, this message translates to:
  /// **'福慧圓滿，共成佛道！'**
  String get calendarGoalReached;

  /// 選中日期尚未達成每日目標
  ///
  /// In zh, this message translates to:
  /// **'持續精進...'**
  String get calendarGoalInProgress;

  /// 每日目標設定面板標題
  ///
  /// In zh, this message translates to:
  /// **'設定每日功課目標'**
  String get dailyGoalSheetTitle;

  /// 月曆設定卡：每日目標列標題
  ///
  /// In zh, this message translates to:
  /// **'每日功課目標'**
  String get dailyGoalRowTitle;

  /// 每日目標列說明
  ///
  /// In zh, this message translates to:
  /// **'以當日手動 + 自動總聲數計算達成'**
  String get dailyGoalRowSubtitle;

  /// 每日目標列右側數值
  ///
  /// In zh, this message translates to:
  /// **'{count} 聲'**
  String dailyGoalValue(int count);

  /// 月曆設定卡：提醒開關標題
  ///
  /// In zh, this message translates to:
  /// **'每日定時念佛提醒'**
  String get reminderTitle;

  /// Toast：開啟提醒
  ///
  /// In zh, this message translates to:
  /// **'已開啟每日定時提醒'**
  String get reminderEnabledToast;

  /// Toast：關閉提醒
  ///
  /// In zh, this message translates to:
  /// **'已關閉定時提醒'**
  String get reminderDisabledToast;

  /// 提醒時間列；time 為 HH:mm
  ///
  /// In zh, this message translates to:
  /// **'每天 {time} 推播提醒'**
  String reminderDailyAt(String time);

  /// 提醒時間列：更換時間
  ///
  /// In zh, this message translates to:
  /// **'更換時間'**
  String get reminderChangeTime;

  /// 月曆設定卡：桌面小工具標題
  ///
  /// In zh, this message translates to:
  /// **'iOS / Android 桌面小工具'**
  String get widgetCardTitle;

  /// 桌面小工具說明
  ///
  /// In zh, this message translates to:
  /// **'支援桌面 Widget，隨時在手機主畫面檢視今日精進、連續天數與每週累計。精進數據已自動即時同步。'**
  String get widgetCardBody;

  /// Toast：已同步小工具
  ///
  /// In zh, this message translates to:
  /// **'已同步最新數據至桌面小工具'**
  String get widgetSyncedToast;

  /// 按鈕：立即同步小工具 (長按顯示診斷)
  ///
  /// In zh, this message translates to:
  /// **'立即同步桌面小工具'**
  String get widgetSyncNow;

  /// 診斷報告：未知值
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get diagUnknown;

  /// 診斷報告：無資料
  ///
  /// In zh, this message translates to:
  /// **'無'**
  String get diagNone;

  /// 診斷報告首行
  ///
  /// In zh, this message translates to:
  /// **'=== 桌面小工具診斷報告 ==='**
  String get diagReportTitle;

  /// 診斷報告：套件 ID
  ///
  /// In zh, this message translates to:
  /// **'應用套件識別碼 (Package ID): {pkg}'**
  String diagPackageId(String pkg);

  /// 診斷報告：版本
  ///
  /// In zh, this message translates to:
  /// **'應用版本 (Version): {ver}'**
  String diagVersion(String ver);

  /// 診斷報告段落標題
  ///
  /// In zh, this message translates to:
  /// **'[候選 App Group 清單]'**
  String get diagCandidateGroups;

  /// 診斷報告段落標題
  ///
  /// In zh, this message translates to:
  /// **'[各群組數據讀取測試]'**
  String get diagGroupData;

  /// 診斷報告段落標題
  ///
  /// In zh, this message translates to:
  /// **'[系統已安裝小工具]'**
  String get diagInstalledWidgets;

  /// 診斷報告：未安裝小工具
  ///
  /// In zh, this message translates to:
  /// **'無 (尚未偵測到主畫面已加入小工具)'**
  String get diagNoWidgets;

  /// 診斷對話框標題
  ///
  /// In zh, this message translates to:
  /// **'小工具診斷資訊'**
  String get diagDialogTitle;

  /// 診斷對話框說明
  ///
  /// In zh, this message translates to:
  /// **'💡 診斷提示：iOS 桌面小工具必須依賴 Apple 官方簽署之 App Group 跨進程共享數據。若透過免費個人 Apple ID 經由 Sideloadly 側載，Apple 會限制該權限導致小工具顯示未連線；若使用付費開發者帳號或 TestFlight 簽署，則可完整即時同步。'**
  String get diagHint;

  /// Toast：已複製診斷報告
  ///
  /// In zh, this message translates to:
  /// **'已複製診斷報告至剪貼簿'**
  String get diagCopiedToast;

  /// 按鈕：複製診斷報告
  ///
  /// In zh, this message translates to:
  /// **'複製報告'**
  String get diagCopy;

  /// 佛曲分類：四字「阿彌陀佛」
  ///
  /// In zh, this message translates to:
  /// **'四字彌陀'**
  String get chantTagFourCharAmitabha;

  /// 佛曲分類：六字「南無阿彌陀佛」
  ///
  /// In zh, this message translates to:
  /// **'六字彌陀'**
  String get chantTagSixCharAmitabha;

  /// 佛曲分類：菩薩聖號與咒語
  ///
  /// In zh, this message translates to:
  /// **'菩薩・持咒'**
  String get chantTagBodhisattvaMantra;

  /// 佛曲分類：朝山聖號
  ///
  /// In zh, this message translates to:
  /// **'朝山聖號'**
  String get chantTagPilgrimage;

  /// 佛曲分類：靈巖山寺梵唄
  ///
  /// In zh, this message translates to:
  /// **'靈巖梵唄'**
  String get chantTagLingyan;

  /// 佛曲分類：法師大德領唱
  ///
  /// In zh, this message translates to:
  /// **'法師大德'**
  String get chantTagMasterChant;

  /// 佛曲分類：快板或中板
  ///
  /// In zh, this message translates to:
  /// **'快中板'**
  String get chantTagBriskMedium;

  /// 佛曲分類：慢板
  ///
  /// In zh, this message translates to:
  /// **'慢板'**
  String get chantTagSlowSolemn;

  /// 通用：播放
  ///
  /// In zh, this message translates to:
  /// **'播放'**
  String get commonPlay;

  /// 通用：返回
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get commonBack;

  /// 播放器副標：演出者、專輯、每拍秒數 (seconds 為小數兩位字串)
  ///
  /// In zh, this message translates to:
  /// **'{artist} · {album} · 每拍 {seconds} 秒'**
  String playerArtistAlbumBeat(String artist, String album, String seconds);

  /// 迷你播放列副標
  ///
  /// In zh, this message translates to:
  /// **'{artist} · 每拍 {seconds}s'**
  String playerArtistBeat(String artist, String seconds);

  /// 迷你播放器副標
  ///
  /// In zh, this message translates to:
  /// **'{artist} · 每拍 {seconds}s · 點擊展開播放器'**
  String miniPlayerSubtitle(String artist, String seconds);

  /// Tooltip：目前為單曲循環
  ///
  /// In zh, this message translates to:
  /// **'單曲循環'**
  String get playerLoopOne;

  /// Tooltip：目前為清單播放
  ///
  /// In zh, this message translates to:
  /// **'清單播放'**
  String get playerLoopList;

  /// Tooltip：上一首
  ///
  /// In zh, this message translates to:
  /// **'上一首'**
  String get playerPrevious;

  /// Tooltip：下一首
  ///
  /// In zh, this message translates to:
  /// **'下一首'**
  String get playerNext;

  /// Tooltip：倒退 10 秒
  ///
  /// In zh, this message translates to:
  /// **'倒退 10 秒'**
  String get playerRewind10;

  /// Tooltip：快轉 10 秒
  ///
  /// In zh, this message translates to:
  /// **'快轉 10 秒'**
  String get playerForward10;

  /// 佛曲頁搜尋框 placeholder
  ///
  /// In zh, this message translates to:
  /// **'搜尋 {count} 首佛曲名稱...'**
  String playerSearchHint(int count);

  /// 分類篩選：全部 (曲目數)
  ///
  /// In zh, this message translates to:
  /// **'全部 ({count})'**
  String songListAll(int count);

  /// 分類篩選晶片：標籤名稱與曲目數
  ///
  /// In zh, this message translates to:
  /// **'{tag} ({count})'**
  String tagWithCount(String tag, int count);

  /// 佛曲頁搜尋無結果
  ///
  /// In zh, this message translates to:
  /// **'無相符的佛曲'**
  String get playerNoMatch;

  /// 播放器佛曲選單搜尋無結果
  ///
  /// In zh, this message translates to:
  /// **'無相符佛曲'**
  String get songMenuNoMatch;

  /// Tooltip：展開佛曲選單
  ///
  /// In zh, this message translates to:
  /// **'展開佛曲選單'**
  String get songMenuExpand;

  /// Tooltip：收合佛曲選單
  ///
  /// In zh, this message translates to:
  /// **'收合佛曲選單'**
  String get songMenuCollapse;

  /// 佛曲選單已展開時的把手文字
  ///
  /// In zh, this message translates to:
  /// **'佛曲選單（共 {count} 首） · 點擊收合'**
  String songMenuHeaderExpanded(int count);

  /// 佛曲選單收合時的把手文字
  ///
  /// In zh, this message translates to:
  /// **'上滑展開佛曲選單（共 {count} 首）'**
  String songMenuHeaderCollapsed(int count);

  /// 佛曲選單搜尋框 placeholder
  ///
  /// In zh, this message translates to:
  /// **'搜尋佛曲名稱、法師或標籤...'**
  String get songMenuSearchHint;

  /// Tooltip：收合佛曲選單回播放器
  ///
  /// In zh, this message translates to:
  /// **'收合回播放器'**
  String get songMenuBackToPlayer;

  /// 曲目列：每拍秒數
  ///
  /// In zh, this message translates to:
  /// **'{seconds}s/拍'**
  String songTileBeat(String seconds);

  /// 經典模式佛曲清單頁標題
  ///
  /// In zh, this message translates to:
  /// **'佛曲清單'**
  String get legacySongListTitle;

  /// 迴向頁佛號
  ///
  /// In zh, this message translates to:
  /// **'南無阿彌陀佛'**
  String get practiceBuddhaName;

  /// 迴向頁敲引磬後的 Toast
  ///
  /// In zh, this message translates to:
  /// **'合十迴向 功德圓滿'**
  String get practiceBellToast;

  /// 迴向頁敲引磬按鈕
  ///
  /// In zh, this message translates to:
  /// **'引磬'**
  String get practiceBellButton;

  /// Tooltip：上一則迴向文
  ///
  /// In zh, this message translates to:
  /// **'上一則迴向文'**
  String get huiXiangPrevTooltip;

  /// Tooltip：下一則迴向文
  ///
  /// In zh, this message translates to:
  /// **'下一則迴向文'**
  String get huiXiangNextTooltip;

  /// 導覽：功能 1 標題
  ///
  /// In zh, this message translates to:
  /// **'念佛與自動計數'**
  String get guideFeatureCountTitle;

  /// 導覽：功能 1 說明
  ///
  /// In zh, this message translates to:
  /// **'全螢幕點擊、引磬木魚原音；或隨 {count} 首精選佛曲自動節拍計數。'**
  String guideFeatureCountDesc(int count);

  /// 導覽：功能 2 標題
  ///
  /// In zh, this message translates to:
  /// **'每日功課表記'**
  String get guideFeatureCalendarTitle;

  /// 導覽：功能 2 說明
  ///
  /// In zh, this message translates to:
  /// **'最右側月曆隨時查閱每天精進進度，支援自由手動修改增減。'**
  String get guideFeatureCalendarDesc;

  /// 導覽：功能 3 標題
  ///
  /// In zh, this message translates to:
  /// **'桌面小工具與定時提醒'**
  String get guideFeatureWidgetTitle;

  /// 導覽：功能 3 說明
  ///
  /// In zh, this message translates to:
  /// **'支援手機桌面 Widget 與每日定時念佛推播提醒，念念相續。'**
  String get guideFeatureWidgetDesc;

  /// 導覽：功能 4 標題
  ///
  /// In zh, this message translates to:
  /// **'現代與經典雙風格'**
  String get guideFeatureModeTitle;

  /// 導覽：功能 4 說明
  ///
  /// In zh, this message translates to:
  /// **'右上角一鍵自由切換現代禪意與經典復古模式，修行更隨心。'**
  String get guideFeatureModeDesc;

  /// 導覽對話框頂部小標籤
  ///
  /// In zh, this message translates to:
  /// **'全新升級重點'**
  String get guideBadge;

  /// Tooltip：關閉導覽
  ///
  /// In zh, this message translates to:
  /// **'關閉導覽'**
  String get guideCloseTooltip;

  /// 導覽對話框標題
  ///
  /// In zh, this message translates to:
  /// **'全新功能特色'**
  String get guideTitle;

  /// 導覽對話框副標
  ///
  /// In zh, this message translates to:
  /// **'專為靜心念佛與拜佛打造的精進夥伴'**
  String get guideSubtitle;

  /// 導覽對話框完成按鈕
  ///
  /// In zh, this message translates to:
  /// **'開始精進'**
  String get guideStart;

  /// 關於頁標題 (作者小站名稱)
  ///
  /// In zh, this message translates to:
  /// **'阿忠小站'**
  String get aboutTitle;

  /// 關於頁 App 名稱
  ///
  /// In zh, this message translates to:
  /// **'念佛計數器 (BuddhaCounter)'**
  String get aboutAppName;

  /// 關於頁版本號
  ///
  /// In zh, this message translates to:
  /// **'版本 {version}'**
  String aboutVersion(String version);

  /// 關於頁段落標題
  ///
  /// In zh, this message translates to:
  /// **'【 阿忠小站 · 緣起與傳承 】'**
  String get aboutHeading;

  /// 關於頁緣起內文
  ///
  /// In zh, this message translates to:
  /// **'本應用程式由李義忠（阿忠）居士發心設計開發，最初於 Android 早期發布，旨在提供十方念佛、拜佛同修一個方便、純粹的隨身精進記數工具。\n\n為使阿忠的心血得以長久傳承、並服務更多現代修行大眾，現由後輩工程師接棒維護，推出全新的操作介面。\n\n祈願一切見聞者，皆發菩提心，一向專念南無阿彌陀佛，同生極樂國。'**
  String get aboutBody;

  /// 關於頁：開啟作者網站按鈕
  ///
  /// In zh, this message translates to:
  /// **'瀏覽阿忠小站 (https://www.leeyc.net)'**
  String get aboutVisitSite;

  /// 關於頁：iOS 隱私權政策
  ///
  /// In zh, this message translates to:
  /// **'iOS 隱私權政策'**
  String get aboutPrivacyIos;

  /// 關於頁：Android 隱私權政策
  ///
  /// In zh, this message translates to:
  /// **'Android 隱私權政策'**
  String get aboutPrivacyAndroid;

  /// 經典模式自動計數頁標題
  ///
  /// In zh, this message translates to:
  /// **'念佛自動計數'**
  String get legacyAutoTitle;

  /// 經典自動計數頁：選曲按鈕 (兩行)
  ///
  /// In zh, this message translates to:
  /// **'念佛\n曲目'**
  String get legacyAutoSongButton;

  /// 經典模式計時標籤
  ///
  /// In zh, this message translates to:
  /// **'計時：'**
  String get legacyTimerLabel;

  /// 經典自動計數頁音訊位置標籤
  ///
  /// In zh, this message translates to:
  /// **'音訊：'**
  String get legacyAudioLabel;

  /// 經典自動計數頁定時關閉標籤
  ///
  /// In zh, this message translates to:
  /// **'自動關閉：'**
  String get legacyAutoStopLabel;

  /// 經典自動計數頁定時關閉單位
  ///
  /// In zh, this message translates to:
  /// **' 分鐘後'**
  String get legacyMinutesLater;

  /// 經典模式按鈕：歸 0
  ///
  /// In zh, this message translates to:
  /// **'歸0'**
  String get legacyResetZero;

  /// 經典模式按鈕：念佛 (播放)
  ///
  /// In zh, this message translates to:
  /// **'念佛'**
  String get legacyChant;

  /// 經典自動計數頁按鈕：顯示音訊位置
  ///
  /// In zh, this message translates to:
  /// **'音訊'**
  String get legacyAudio;

  /// 經典模式念佛 (迴向) 頁標題
  ///
  /// In zh, this message translates to:
  /// **'念佛頁面'**
  String get legacyChantTitle;

  /// 經典模式：返回首頁按鈕
  ///
  /// In zh, this message translates to:
  /// **'返回首頁'**
  String get legacyBackHome;

  /// 經典模式升級介紹對話框標題
  ///
  /// In zh, this message translates to:
  /// **'念佛計數器 · 全新升級！'**
  String get legacyUpgradeTitle;

  /// 經典模式升級介紹對話框內文
  ///
  /// In zh, this message translates to:
  /// **'已為您推出全新的「現代禪意模式」，包含沉浸圓環計數、自訂目標聲數、隨身佛曲播放器與晝夜護眼主題。\n\n您可隨時切換體驗，日後亦可自由切換回熟悉的經典模式。'**
  String get legacyUpgradeBody;

  /// 升級介紹：保留經典模式
  ///
  /// In zh, this message translates to:
  /// **'保留經典模式'**
  String get legacyKeepClassic;

  /// 升級介紹：切換到現代模式
  ///
  /// In zh, this message translates to:
  /// **'立即體驗新版'**
  String get legacyTryModern;

  /// 經典模式 Toast：已解除方向鎖定
  ///
  /// In zh, this message translates to:
  /// **'已解除鎖定'**
  String get legacyUnlockedToast;

  /// 經典模式：切換到現代模式 (tooltip / 選單)
  ///
  /// In zh, this message translates to:
  /// **'切換至現代模式'**
  String get legacySwitchToModern;

  /// Toast：已切到現代模式
  ///
  /// In zh, this message translates to:
  /// **'已切換為現代模式'**
  String get switchedToModernToast;

  /// 經典模式設定 (tooltip 與設定頁標題)
  ///
  /// In zh, this message translates to:
  /// **'設定'**
  String get legacySettingsTitle;

  /// 經典模式選單：功課月曆
  ///
  /// In zh, this message translates to:
  /// **'功課月曆表記'**
  String get legacyCalendarMenu;

  /// 經典模式選單：偏好設定
  ///
  /// In zh, this message translates to:
  /// **'偏好設定'**
  String get legacyPreferences;

  /// 經典模式選單：導覽說明
  ///
  /// In zh, this message translates to:
  /// **'了解現代禪意模式與新功能'**
  String get legacyGuideSubtitle;

  /// 經典模式按鈕：減 1
  ///
  /// In zh, this message translates to:
  /// **'減1'**
  String get legacyMinusOne;

  /// 經典模式按鈕：前往迴向頁
  ///
  /// In zh, this message translates to:
  /// **'迴向頁'**
  String get legacyDedicationPage;

  /// 經典模式按鈕：前往計數頁
  ///
  /// In zh, this message translates to:
  /// **'計數頁'**
  String get legacyCounterPage;

  /// 經典模式按鈕：停止計時
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get legacyStop;

  /// 經典模式按鈕：佛曲清單
  ///
  /// In zh, this message translates to:
  /// **'佛曲'**
  String get legacySongs;

  /// 經典設定：螢幕常亮開關標題
  ///
  /// In zh, this message translates to:
  /// **'保持螢幕常亮（防止休眠）'**
  String get legacyKeepScreenOnTitle;

  /// 經典設定：螢幕常亮說明
  ///
  /// In zh, this message translates to:
  /// **'開啟後計數、念佛與播放佛曲時不會自動關閉螢幕，亦可直接於各頁面頂部右上角快捷鍵切換'**
  String get legacyKeepScreenOnDesc;

  /// 經典設定：點擊音效標題
  ///
  /// In zh, this message translates to:
  /// **'點擊計數音效'**
  String get legacyClickSoundTitle;

  /// 音效名稱：木魚一
  ///
  /// In zh, this message translates to:
  /// **'木魚一'**
  String get soundWoodfish1;

  /// 音效名稱：木魚二 (經典原音)
  ///
  /// In zh, this message translates to:
  /// **'木魚二 (經典原音)'**
  String get soundWoodfish2;

  /// 音效名稱：引磬
  ///
  /// In zh, this message translates to:
  /// **'引磬聲'**
  String get soundBell;

  /// 音效名稱：靜音
  ///
  /// In zh, this message translates to:
  /// **'靜音'**
  String get soundMute;

  /// 經典設定：介面模式標題
  ///
  /// In zh, this message translates to:
  /// **'介面模式切換'**
  String get legacyUiModeTitle;

  /// 介面模式：經典
  ///
  /// In zh, this message translates to:
  /// **'經典模式'**
  String get legacyClassicMode;

  /// 介面模式：現代
  ///
  /// In zh, this message translates to:
  /// **'現代模式'**
  String get legacyModernMode;

  /// 經典設定：儲存並返回按鈕
  ///
  /// In zh, this message translates to:
  /// **'儲存並返回'**
  String get legacySaveAndBack;

  /// 桌面小工具日期；monthShort 為英文月份縮寫
  ///
  /// In zh, this message translates to:
  /// **'{month}月{day}日'**
  String widgetDate(int month, int day, String monthShort);

  /// 桌面小工具：每日目標進度
  ///
  /// In zh, this message translates to:
  /// **'目標 {percent}% ({today}/{target})'**
  String widgetTargetText(int percent, int today, int target);

  /// 桌面小工具：未設每日目標時
  ///
  /// In zh, this message translates to:
  /// **'今日累積 {today} 聲 (不限目標)'**
  String widgetTodayNoGoal(int today);

  /// 桌面小工具：連續天數
  ///
  /// In zh, this message translates to:
  /// **'🔥 連續 {days} 天'**
  String widgetStreak(int days);

  /// 桌面小工具：尚無連續天數
  ///
  /// In zh, this message translates to:
  /// **'今日精進念佛'**
  String get widgetStreakNone;

  /// 桌面小工具：本週累計
  ///
  /// In zh, this message translates to:
  /// **'本週: {count}聲'**
  String widgetWeekly(int count);

  /// 桌面小工具：本月累計
  ///
  /// In zh, this message translates to:
  /// **'本月: {count}聲'**
  String widgetMonthly(int count);

  /// 桌面小工具：重新整理按鈕 (無障礙說明)
  ///
  /// In zh, this message translates to:
  /// **'重新整理'**
  String get widgetRefresh;

  /// Android 通知頻道名稱：每日提醒
  ///
  /// In zh, this message translates to:
  /// **'精進日課提醒'**
  String get reminderChannelName;

  /// Android 通知頻道說明：每日提醒
  ///
  /// In zh, this message translates to:
  /// **'簡單的事情每天做，就會變成不簡單。'**
  String get reminderChannelDesc;

  /// 每日提醒通知標題
  ///
  /// In zh, this message translates to:
  /// **'今日精進功課'**
  String get reminderNotifTitle;

  /// 每日提醒通知內文
  ///
  /// In zh, this message translates to:
  /// **'開啟念佛計數器填寫今日功課數吧！'**
  String get reminderNotifBody;

  /// Android 通知頻道名稱：目標達成
  ///
  /// In zh, this message translates to:
  /// **'目標達成通知'**
  String get milestoneChannelName;

  /// Android 通知頻道說明：目標達成
  ///
  /// In zh, this message translates to:
  /// **'發送目標達成與精進里程碑通知'**
  String get milestoneChannelDesc;

  /// Android 通知頻道名稱：背景播放
  ///
  /// In zh, this message translates to:
  /// **'念佛計數器佛曲播放'**
  String get audioChannelName;

  /// 背景播放頻道說明與鎖定畫面描述
  ///
  /// In zh, this message translates to:
  /// **'保持螢幕休眠或退至背景時佛曲持續播放'**
  String get audioChannelDesc;

  /// 鎖定畫面副標：演出者 · 專輯
  ///
  /// In zh, this message translates to:
  /// **'{artist} · {album}'**
  String mediaSubtitle(String artist, String album);
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
