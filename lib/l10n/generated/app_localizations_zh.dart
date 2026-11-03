// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '念佛計數器';

  @override
  String get commonCancel => '取消';

  @override
  String get commonConfirm => '確認';

  @override
  String get commonSet => '設定';

  @override
  String get commonClose => '關閉';

  @override
  String get languageMenuTitle => '語言';

  @override
  String get languageFollowSystem => '跟隨系統';

  @override
  String get commonStart => '開始';

  @override
  String get commonPause => '暫停';

  @override
  String get tabManual => '手動計數';

  @override
  String get tabAuto => '自動計數';

  @override
  String get tabDedication => '迴向';

  @override
  String get tabCalendar => '功課月曆';

  @override
  String get themeSwitchedLightToast => '已切換為淺色模式';

  @override
  String get themeSwitchedDarkToast => '已切換為深色模式';

  @override
  String get themeToLightTooltip => '切換為淺色模式';

  @override
  String get themeToDarkTooltip => '切換為深色模式';

  @override
  String get orientationUnlockTooltip => '解除方向鎖定';

  @override
  String get orientationLockTooltip => '鎖定螢幕方向';

  @override
  String get orientationLockedToast => '已鎖定螢幕方向';

  @override
  String get orientationUnlockedToast => '已解除方向鎖定';

  @override
  String get screenAwakeOn => '螢幕常亮';

  @override
  String get screenAwakeOffTooltip => '關閉螢幕常亮';

  @override
  String get screenAwakeOffToast => '已關閉螢幕常亮';

  @override
  String get switchToClassicMode => '切換回經典模式';

  @override
  String get switchedToClassicToast => '已切換為經典模式';

  @override
  String get drawerHeaderTitle => '念佛、拜佛記數器';

  @override
  String get drawerHeaderSubtitle => '南無阿彌陀佛';

  @override
  String get drawerSongList => '選擇佛曲清單';

  @override
  String get drawerGuide => '新版功能導覽教學';

  @override
  String get drawerAbout => '阿忠小站 · 緣起傳承';

  @override
  String get counterResetConfirmTitle => '確認要歸零嗎？';

  @override
  String counterResetConfirmBody(int count) {
    return '目前計數為$count';
  }

  @override
  String get counterResetConfirmAction => '確認歸零';

  @override
  String get counterResetDoneToast => '已歸零';

  @override
  String get manualGoalSheetTitle => '設定手動計數目標';

  @override
  String get timerResetTooltip => '重設計時';

  @override
  String goalChipLabel(int count) {
    return '目標 $count';
  }

  @override
  String get goalChipUnlimited => '目標 不限';

  @override
  String get counterMinusOne => '減一';

  @override
  String get counterResetShort => '歸零';

  @override
  String get soundEffectTitle => '音效';

  @override
  String get soundChipWoodfish1 => '木魚1';

  @override
  String get soundChipWoodfish2 => '木魚2';

  @override
  String get soundChipBell => '引磬';

  @override
  String get soundChipMute => '靜音';

  @override
  String get vibrationFeedback => '震動回饋';

  @override
  String get fullscreenTap => '全螢幕點擊';

  @override
  String get zenCircleUnitLabel => '聲 · 拜';

  @override
  String goalProgressLabel(int count, int percent) {
    return '目標 $count · $percent%';
  }

  @override
  String goalReachedLabel(int count) {
    return '達成 $count 聲';
  }

  @override
  String get goalUnlimited => '不限目標';

  @override
  String goalCustomChip(int value) {
    return '$value(自訂)';
  }

  @override
  String get goalCustomPrompt => '或自訂目標聲數：';

  @override
  String get goalCustomHint => '輸入目標 (如 500)';

  @override
  String get unitRecitationsSuffix => '聲';

  @override
  String get goalInvalidNumber => '請輸入大於 0 的有效目標數字';

  @override
  String get goalSetUnlimitedToast => '已設定為不限目標';

  @override
  String goalSetToast(int count) {
    return '已設定目標：$count 聲';
  }

  @override
  String get autoStopSheetTitle => '設定自動停止';

  @override
  String get autoStopExclusiveHint => '聲數與時間只能擇一，設定其中一項會清空另一項。';

  @override
  String get autoStopByCountTitle => '念滿聲數停止';

  @override
  String get autoStopByTimeTitle => '定時停止';

  @override
  String autoCountChip(int count) {
    return '$count 聲';
  }

  @override
  String autoCountCustomChip(int count) {
    return '$count 聲 (自訂)';
  }

  @override
  String autoCountGoalSetToast(int count) {
    return '已設定念滿 $count 聲自動停止';
  }

  @override
  String get autoCountGoalClearedToast => '已取消聲數目標，持續播放';

  @override
  String autoMinutesChip(int minutes) {
    return '$minutes 分鐘';
  }

  @override
  String autoMinutesCustomChip(int minutes) {
    return '$minutes 分鐘 (自訂)';
  }

  @override
  String get autoMinutesPrompt => '或自訂分鐘數：';

  @override
  String get autoMinutesHint => '輸入分鐘數 (如 20)';

  @override
  String get unitMinutesSuffix => '分鐘';

  @override
  String get autoMinutesInvalid => '請輸入大於 0 的有效分鐘數';

  @override
  String autoTimerSetToast(int minutes) {
    return '已設定定時停止：$minutes 分鐘';
  }

  @override
  String get autoTimerClearedToast => '已取消定時停止，持續播放';

  @override
  String get autoStopClearAction => '清除設定，持續播放';

  @override
  String get autoStopClearedToast => '已清除設定，持續播放';

  @override
  String get autoAlreadyZeroToast => '目前計數已為 0';

  @override
  String get autoResetConfirmTitle => '重設自動計數？';

  @override
  String autoResetConfirmBody(int count) {
    return '目前自動計數為 $count 聲，確定要歸零重置嗎？\n（計時時間將會保留）';
  }

  @override
  String get autoResetConfirmAction => '確認重置';

  @override
  String get autoResetDoneToast => '自動計數已重置為 0';

  @override
  String get autoTimerResetToast => '計時已重置';

  @override
  String autoTimeProgressLabel(int minutes, String remaining) {
    return '定時 $minutes 分 · 剩 $remaining';
  }

  @override
  String autoTimeReachedLabel(int minutes) {
    return '定時 $minutes 分 · 已到';
  }

  @override
  String autoTimerChip(int minutes) {
    return '定時 $minutes 分';
  }

  @override
  String get autoContinuous => '持續播放';

  @override
  String get autoCircleUnitLabel => '聲 · 遍';

  @override
  String autoBeatHint(String seconds) {
    return '每拍 ${seconds}s 自動累加';
  }

  @override
  String get autoResetShort => '重置';

  @override
  String autoRemainingMinutes(int minutes) {
    return '$minutes 分';
  }

  @override
  String autoRemainingSeconds(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get calendarPrevYear => '上一年';

  @override
  String get calendarNextYear => '下一年';

  @override
  String calendarYearLabel(int year) {
    return '$year 年';
  }

  @override
  String calendarMonthChip(int month, String monthShort) {
    return '$month 月';
  }

  @override
  String get calendarBackToThisMonth => '回到本月';

  @override
  String get calendarEditTitle => '手動修改功課聲數';

  @override
  String calendarEditDateLabel(int year, int month, int day, String monthName) {
    return '日期：$year年$month月$day日';
  }

  @override
  String get calendarEditFieldLabel => '今日功課聲數';

  @override
  String get calendarEditFieldHint => '請輸入念佛聲數';

  @override
  String get calendarEditSave => '確認儲存';

  @override
  String calendarEditSavedToast(int count) {
    return '已更新功課紀錄為 $count 聲';
  }

  @override
  String get reminderPickerHelp => '選擇每日念佛提醒時間';

  @override
  String reminderSetToast(String time) {
    return '已設定每日 $time 定時提醒';
  }

  @override
  String streakBanner(int days) {
    return '連續精進 $days 天';
  }

  @override
  String get streakBadge => '精進不懈';

  @override
  String get streakEncourageActive => '念念相續，功德無量！繼續保持今日精進。';

  @override
  String get streakEncourageStart => '今日開啟第一聲佛號，建立每日精進習慣！';

  @override
  String get metricToday => '今日功課';

  @override
  String get metricWeek => '本週累計';

  @override
  String get metricMonth => '本月累計';

  @override
  String metricTodayGoal(int goal, int percent) {
    return '目標 $goal ($percent%)';
  }

  @override
  String get metricNoGoal => '無目標';

  @override
  String get metricWeekSubtitle => '週一至週日';

  @override
  String metricMonthSubtitle(int month, String monthShort) {
    return '$month月總和';
  }

  @override
  String compactNumber(String tenThousands, String thousands) {
    return '$tenThousands萬';
  }

  @override
  String get metricUnit => '聲';

  @override
  String get calendarPrevMonth => '上一月';

  @override
  String get calendarNextMonth => '下一月';

  @override
  String calendarMonthTitle(int year, int month, String monthName) {
    return '$year 年 $month 月';
  }

  @override
  String get calendarToday => '今天';

  @override
  String get weekdaySun => '日';

  @override
  String get weekdayMon => '一';

  @override
  String get weekdayTue => '二';

  @override
  String get weekdayWed => '三';

  @override
  String get weekdayThu => '四';

  @override
  String get weekdayFri => '五';

  @override
  String get weekdaySat => '六';

  @override
  String calendarSelectedDate(int year, int month, int day, String monthName) {
    return '$year 年 $month 月 $day 日';
  }

  @override
  String get calendarTodayBadge => '今日';

  @override
  String get calendarEditButton => '修改數值';

  @override
  String get calendarCountUnit => '聲佛號';

  @override
  String calendarBreakdown(int manual, int auto) {
    return '手動: $manual · 自動: $auto';
  }

  @override
  String get calendarGoalReached => '福慧圓滿，共成佛道！';

  @override
  String get calendarGoalInProgress => '持續精進...';

  @override
  String get dailyGoalSheetTitle => '設定每日功課目標';

  @override
  String get dailyGoalRowTitle => '每日功課目標';

  @override
  String get dailyGoalRowSubtitle => '以當日手動 + 自動總聲數計算達成';

  @override
  String dailyGoalValue(int count) {
    return '$count 聲';
  }

  @override
  String get reminderTitle => '每日定時念佛提醒';

  @override
  String get reminderEnabledToast => '已開啟每日定時提醒';

  @override
  String get reminderDisabledToast => '已關閉定時提醒';

  @override
  String reminderDailyAt(String time) {
    return '每天 $time 推播提醒';
  }

  @override
  String get reminderChangeTime => '更換時間';

  @override
  String get widgetCardTitle => 'iOS / Android 桌面小工具';

  @override
  String get widgetCardBody =>
      '支援桌面 Widget，隨時在手機主畫面檢視今日精進、連續天數與每週累計。精進數據已自動即時同步。';

  @override
  String get widgetSyncedToast => '已同步最新數據至桌面小工具';

  @override
  String get widgetSyncNow => '立即同步桌面小工具';

  @override
  String get diagUnknown => '未知';

  @override
  String get diagNone => '無';

  @override
  String get diagReportTitle => '=== 桌面小工具診斷報告 ===';

  @override
  String diagPackageId(String pkg) {
    return '應用套件識別碼 (Package ID): $pkg';
  }

  @override
  String diagVersion(String ver) {
    return '應用版本 (Version): $ver';
  }

  @override
  String get diagCandidateGroups => '[候選 App Group 清單]';

  @override
  String get diagGroupData => '[各群組數據讀取測試]';

  @override
  String get diagInstalledWidgets => '[系統已安裝小工具]';

  @override
  String get diagNoWidgets => '無 (尚未偵測到主畫面已加入小工具)';

  @override
  String get diagDialogTitle => '小工具診斷資訊';

  @override
  String get diagHint =>
      '💡 診斷提示：iOS 桌面小工具必須依賴 Apple 官方簽署之 App Group 跨進程共享數據。若透過免費個人 Apple ID 經由 Sideloadly 側載，Apple 會限制該權限導致小工具顯示未連線；若使用付費開發者帳號或 TestFlight 簽署，則可完整即時同步。';

  @override
  String get diagCopiedToast => '已複製診斷報告至剪貼簿';

  @override
  String get diagCopy => '複製報告';

  @override
  String get chantTagFourCharAmitabha => '四字彌陀';

  @override
  String get chantTagSixCharAmitabha => '六字彌陀';

  @override
  String get chantTagBodhisattvaMantra => '菩薩・持咒';

  @override
  String get chantTagPilgrimage => '朝山聖號';

  @override
  String get chantTagLingyan => '靈巖梵唄';

  @override
  String get chantTagMasterChant => '法師大德';

  @override
  String get chantTagBriskMedium => '快中板';

  @override
  String get chantTagSlowSolemn => '慢板';

  @override
  String get commonPlay => '播放';

  @override
  String get commonBack => '返回';

  @override
  String playerArtistAlbumBeat(String artist, String album, String seconds) {
    return '$artist · $album · 每拍 $seconds 秒';
  }

  @override
  String playerArtistBeat(String artist, String seconds) {
    return '$artist · 每拍 ${seconds}s';
  }

  @override
  String miniPlayerSubtitle(String artist, String seconds) {
    return '$artist · 每拍 ${seconds}s · 點擊展開播放器';
  }

  @override
  String get playerLoopOne => '單曲循環';

  @override
  String get playerLoopList => '清單播放';

  @override
  String get playerPrevious => '上一首';

  @override
  String get playerNext => '下一首';

  @override
  String get playerRewind10 => '倒退 10 秒';

  @override
  String get playerForward10 => '快轉 10 秒';

  @override
  String playerSearchHint(int count) {
    return '搜尋 $count 首佛曲名稱...';
  }

  @override
  String songListAll(int count) {
    return '全部 ($count)';
  }

  @override
  String tagWithCount(String tag, int count) {
    return '$tag ($count)';
  }

  @override
  String get playerNoMatch => '無相符的佛曲';

  @override
  String get songMenuNoMatch => '無相符佛曲';

  @override
  String get songMenuExpand => '展開佛曲選單';

  @override
  String get songMenuCollapse => '收合佛曲選單';

  @override
  String songMenuHeaderExpanded(int count) {
    return '佛曲選單（共 $count 首） · 點擊收合';
  }

  @override
  String songMenuHeaderCollapsed(int count) {
    return '上滑展開佛曲選單（共 $count 首）';
  }

  @override
  String get songMenuSearchHint => '搜尋佛曲名稱、法師或標籤...';

  @override
  String get songMenuBackToPlayer => '收合回播放器';

  @override
  String songTileBeat(String seconds) {
    return '${seconds}s/拍';
  }

  @override
  String get legacySongListTitle => '佛曲清單';

  @override
  String get practiceBuddhaName => '南無阿彌陀佛';

  @override
  String get practiceBellToast => '合十迴向 功德圓滿';

  @override
  String get practiceBellButton => '引磬';

  @override
  String get huiXiangPrevTooltip => '上一則迴向文';

  @override
  String get huiXiangNextTooltip => '下一則迴向文';

  @override
  String get guideFeatureCountTitle => '念佛與自動計數';

  @override
  String guideFeatureCountDesc(int count) {
    return '全螢幕點擊、引磬木魚原音；或隨 $count 首精選佛曲自動節拍計數。';
  }

  @override
  String get guideFeatureCalendarTitle => '每日功課表記';

  @override
  String get guideFeatureCalendarDesc => '最右側月曆隨時查閱每天精進進度，支援自由手動修改增減。';

  @override
  String get guideFeatureWidgetTitle => '桌面小工具與定時提醒';

  @override
  String get guideFeatureWidgetDesc => '支援手機桌面 Widget 與每日定時念佛推播提醒，念念相續。';

  @override
  String get guideFeatureModeTitle => '現代與經典雙風格';

  @override
  String get guideFeatureModeDesc => '右上角一鍵自由切換現代禪意與經典復古模式，修行更隨心。';

  @override
  String get guideBadge => '全新升級重點';

  @override
  String get guideCloseTooltip => '關閉導覽';

  @override
  String get guideTitle => '全新功能特色';

  @override
  String get guideSubtitle => '專為靜心念佛與拜佛打造的精進夥伴';

  @override
  String get guideStart => '開始精進';

  @override
  String get aboutTitle => '阿忠小站';

  @override
  String get aboutAppName => '念佛計數器 (BuddhaCounter)';

  @override
  String aboutVersion(String version) {
    return '版本 $version';
  }

  @override
  String get aboutHeading => '【 阿忠小站 · 緣起與傳承 】';

  @override
  String get aboutBody =>
      '本應用程式由李義忠（阿忠）居士發心設計開發，最初於 Android 早期發布，旨在提供十方念佛、拜佛同修一個方便、純粹的隨身精進記數工具。\n\n為使阿忠的心血得以長久傳承、並服務更多現代修行大眾，現由後輩工程師接棒維護，推出全新的操作介面。\n\n祈願一切見聞者，皆發菩提心，一向專念南無阿彌陀佛，同生極樂國。';

  @override
  String get aboutVisitSite => '瀏覽阿忠小站 (https://www.leeyc.net)';

  @override
  String get aboutPrivacyIos => 'iOS 隱私權政策';

  @override
  String get aboutPrivacyAndroid => 'Android 隱私權政策';

  @override
  String get legacyAutoTitle => '念佛自動計數';

  @override
  String get legacyAutoSongButton => '念佛\n曲目';

  @override
  String get legacyTimerLabel => '計時：';

  @override
  String get legacyAudioLabel => '音訊：';

  @override
  String get legacyAutoStopLabel => '自動關閉：';

  @override
  String get legacyMinutesLater => ' 分鐘後';

  @override
  String get legacyResetZero => '歸0';

  @override
  String get legacyChant => '念佛';

  @override
  String get legacyAudio => '音訊';

  @override
  String get legacyChantTitle => '念佛頁面';

  @override
  String get legacyBackHome => '返回首頁';

  @override
  String get legacyUpgradeTitle => '念佛計數器 · 全新升級！';

  @override
  String get legacyUpgradeBody =>
      '已為您推出全新的「現代禪意模式」，包含沉浸圓環計數、自訂目標聲數、隨身佛曲播放器與晝夜護眼主題。\n\n您可隨時切換體驗，日後亦可自由切換回熟悉的經典模式。';

  @override
  String get legacyKeepClassic => '保留經典模式';

  @override
  String get legacyTryModern => '立即體驗新版';

  @override
  String get legacyUnlockedToast => '已解除鎖定';

  @override
  String get legacySwitchToModern => '切換至現代模式';

  @override
  String get switchedToModernToast => '已切換為現代模式';

  @override
  String get legacySettingsTitle => '設定';

  @override
  String get legacyCalendarMenu => '功課月曆表記';

  @override
  String get legacyPreferences => '偏好設定';

  @override
  String get legacyGuideSubtitle => '了解現代禪意模式與新功能';

  @override
  String get legacyMinusOne => '減1';

  @override
  String get legacyDedicationPage => '迴向頁';

  @override
  String get legacyCounterPage => '計數頁';

  @override
  String get legacyStop => '停止';

  @override
  String get legacySongs => '佛曲';

  @override
  String get legacyKeepScreenOnTitle => '保持螢幕常亮（防止休眠）';

  @override
  String get legacyKeepScreenOnDesc =>
      '開啟後計數、念佛與播放佛曲時不會自動關閉螢幕，亦可直接於各頁面頂部右上角快捷鍵切換';

  @override
  String get legacyClickSoundTitle => '點擊計數音效';

  @override
  String get soundWoodfish1 => '木魚一';

  @override
  String get soundWoodfish2 => '木魚二 (經典原音)';

  @override
  String get soundBell => '引磬聲';

  @override
  String get soundMute => '靜音';

  @override
  String get legacyUiModeTitle => '介面模式切換';

  @override
  String get legacyClassicMode => '經典模式';

  @override
  String get legacyModernMode => '現代模式';

  @override
  String get legacySaveAndBack => '儲存並返回';

  @override
  String widgetDate(int month, int day, String monthShort) {
    return '$month月$day日';
  }

  @override
  String widgetTargetText(int percent, int today, int target) {
    return '目標 $percent% ($today/$target)';
  }

  @override
  String widgetTodayNoGoal(int today) {
    return '今日累積 $today 聲 (不限目標)';
  }

  @override
  String widgetStreak(int days) {
    return '🔥 連續 $days 天';
  }

  @override
  String get widgetStreakNone => '今日精進念佛';

  @override
  String widgetWeekly(int count) {
    return '本週: $count聲';
  }

  @override
  String widgetMonthly(int count) {
    return '本月: $count聲';
  }

  @override
  String get widgetRefresh => '重新整理';

  @override
  String get reminderChannelName => '精進日課提醒';

  @override
  String get reminderChannelDesc => '簡單的事情每天做，就會變成不簡單。';

  @override
  String get reminderNotifTitle => '今日精進功課';

  @override
  String get reminderNotifBody => '開啟念佛計數器填寫今日功課數吧！';

  @override
  String get milestoneChannelName => '目標達成通知';

  @override
  String get milestoneChannelDesc => '發送目標達成與精進里程碑通知';

  @override
  String get audioChannelName => '念佛計數器佛曲播放';

  @override
  String get audioChannelDesc => '保持螢幕休眠或退至背景時佛曲持續播放';

  @override
  String mediaSubtitle(String artist, String album) {
    return '$artist · $album';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get appTitle => '念佛计数器';

  @override
  String get commonCancel => '取消';

  @override
  String get commonConfirm => '确认';

  @override
  String get commonSet => '设定';

  @override
  String get commonClose => '关闭';

  @override
  String get languageMenuTitle => '语言';

  @override
  String get languageFollowSystem => '跟随系统';

  @override
  String get commonStart => '开始';

  @override
  String get commonPause => '暂停';

  @override
  String get tabManual => '手动计数';

  @override
  String get tabAuto => '自动计数';

  @override
  String get tabDedication => '回向';

  @override
  String get tabCalendar => '功课月历';

  @override
  String get themeSwitchedLightToast => '已切换为浅色模式';

  @override
  String get themeSwitchedDarkToast => '已切换为深色模式';

  @override
  String get themeToLightTooltip => '切换为浅色模式';

  @override
  String get themeToDarkTooltip => '切换为深色模式';

  @override
  String get orientationUnlockTooltip => '解除方向锁定';

  @override
  String get orientationLockTooltip => '锁定屏幕方向';

  @override
  String get orientationLockedToast => '已锁定屏幕方向';

  @override
  String get orientationUnlockedToast => '已解除方向锁定';

  @override
  String get screenAwakeOn => '屏幕常亮';

  @override
  String get screenAwakeOffTooltip => '关闭屏幕常亮';

  @override
  String get screenAwakeOffToast => '已关闭屏幕常亮';

  @override
  String get switchToClassicMode => '切换回经典模式';

  @override
  String get switchedToClassicToast => '已切换为经典模式';

  @override
  String get drawerHeaderTitle => '念佛、拜佛记数器';

  @override
  String get drawerHeaderSubtitle => '南无阿弥陀佛';

  @override
  String get drawerSongList => '选择佛曲清单';

  @override
  String get drawerGuide => '新版功能导览教学';

  @override
  String get drawerAbout => '阿忠小站 · 缘起传承';

  @override
  String get counterResetConfirmTitle => '确认要归零吗？';

  @override
  String counterResetConfirmBody(int count) {
    return '目前计数为$count';
  }

  @override
  String get counterResetConfirmAction => '确认归零';

  @override
  String get counterResetDoneToast => '已归零';

  @override
  String get manualGoalSheetTitle => '设定手动计数目标';

  @override
  String get timerResetTooltip => '重设计时';

  @override
  String goalChipLabel(int count) {
    return '目标 $count';
  }

  @override
  String get goalChipUnlimited => '目标 不限';

  @override
  String get counterMinusOne => '减一';

  @override
  String get counterResetShort => '归零';

  @override
  String get soundEffectTitle => '音效';

  @override
  String get soundChipWoodfish1 => '木鱼1';

  @override
  String get soundChipWoodfish2 => '木鱼2';

  @override
  String get soundChipBell => '引磬';

  @override
  String get soundChipMute => '静音';

  @override
  String get vibrationFeedback => '震动反馈';

  @override
  String get fullscreenTap => '全屏点击';

  @override
  String get zenCircleUnitLabel => '声 · 拜';

  @override
  String goalProgressLabel(int count, int percent) {
    return '目标 $count · $percent%';
  }

  @override
  String goalReachedLabel(int count) {
    return '达成 $count 声';
  }

  @override
  String get goalUnlimited => '不限目标';

  @override
  String goalCustomChip(int value) {
    return '$value(自定义)';
  }

  @override
  String get goalCustomPrompt => '或自定义目标声数：';

  @override
  String get goalCustomHint => '输入目标 (如 500)';

  @override
  String get unitRecitationsSuffix => '声';

  @override
  String get goalInvalidNumber => '请输入大于 0 的有效目标数字';

  @override
  String get goalSetUnlimitedToast => '已设定为不限目标';

  @override
  String goalSetToast(int count) {
    return '已设定目标：$count 声';
  }

  @override
  String get autoStopSheetTitle => '设定自动停止';

  @override
  String get autoStopExclusiveHint => '声数与时间只能择一，设定其中一项会清空另一项。';

  @override
  String get autoStopByCountTitle => '念满声数停止';

  @override
  String get autoStopByTimeTitle => '定时停止';

  @override
  String autoCountChip(int count) {
    return '$count 声';
  }

  @override
  String autoCountCustomChip(int count) {
    return '$count 声 (自定义)';
  }

  @override
  String autoCountGoalSetToast(int count) {
    return '已设定念满 $count 声自动停止';
  }

  @override
  String get autoCountGoalClearedToast => '已取消声数目标，持续播放';

  @override
  String autoMinutesChip(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String autoMinutesCustomChip(int minutes) {
    return '$minutes 分钟 (自定义)';
  }

  @override
  String get autoMinutesPrompt => '或自定义分钟数：';

  @override
  String get autoMinutesHint => '输入分钟数 (如 20)';

  @override
  String get unitMinutesSuffix => '分钟';

  @override
  String get autoMinutesInvalid => '请输入大于 0 的有效分钟数';

  @override
  String autoTimerSetToast(int minutes) {
    return '已设定定时停止：$minutes 分钟';
  }

  @override
  String get autoTimerClearedToast => '已取消定时停止，持续播放';

  @override
  String get autoStopClearAction => '清除设定，持续播放';

  @override
  String get autoStopClearedToast => '已清除设定，持续播放';

  @override
  String get autoAlreadyZeroToast => '目前计数已为 0';

  @override
  String get autoResetConfirmTitle => '重设自动计数？';

  @override
  String autoResetConfirmBody(int count) {
    return '目前自动计数为 $count 声，确定要归零重置吗？\n（计时时间将会保留）';
  }

  @override
  String get autoResetConfirmAction => '确认重置';

  @override
  String get autoResetDoneToast => '自动计数已重置为 0';

  @override
  String get autoTimerResetToast => '计时已重置';

  @override
  String autoTimeProgressLabel(int minutes, String remaining) {
    return '定时 $minutes 分 · 剩 $remaining';
  }

  @override
  String autoTimeReachedLabel(int minutes) {
    return '定时 $minutes 分 · 已到';
  }

  @override
  String autoTimerChip(int minutes) {
    return '定时 $minutes 分';
  }

  @override
  String get autoContinuous => '持续播放';

  @override
  String get autoCircleUnitLabel => '声 · 遍';

  @override
  String autoBeatHint(String seconds) {
    return '每拍 ${seconds}s 自动累加';
  }

  @override
  String get autoResetShort => '重置';

  @override
  String autoRemainingMinutes(int minutes) {
    return '$minutes 分';
  }

  @override
  String autoRemainingSeconds(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get calendarPrevYear => '上一年';

  @override
  String get calendarNextYear => '下一年';

  @override
  String calendarYearLabel(int year) {
    return '$year 年';
  }

  @override
  String calendarMonthChip(int month, String monthShort) {
    return '$month 月';
  }

  @override
  String get calendarBackToThisMonth => '回到本月';

  @override
  String get calendarEditTitle => '手动修改功课声数';

  @override
  String calendarEditDateLabel(int year, int month, int day, String monthName) {
    return '日期：$year年$month月$day日';
  }

  @override
  String get calendarEditFieldLabel => '今日功课声数';

  @override
  String get calendarEditFieldHint => '请输入念佛声数';

  @override
  String get calendarEditSave => '确认保存';

  @override
  String calendarEditSavedToast(int count) {
    return '已更新功课记录为 $count 声';
  }

  @override
  String get reminderPickerHelp => '选择每日念佛提醒时间';

  @override
  String reminderSetToast(String time) {
    return '已设定每日 $time 定时提醒';
  }

  @override
  String streakBanner(int days) {
    return '连续精进 $days 天';
  }

  @override
  String get streakBadge => '精进不懈';

  @override
  String get streakEncourageActive => '念念相续，功德无量！继续保持今日精进。';

  @override
  String get streakEncourageStart => '今日开启第一声佛号，建立每日精进习惯！';

  @override
  String get metricToday => '今日功课';

  @override
  String get metricWeek => '本周累计';

  @override
  String get metricMonth => '本月累计';

  @override
  String metricTodayGoal(int goal, int percent) {
    return '目标 $goal ($percent%)';
  }

  @override
  String get metricNoGoal => '无目标';

  @override
  String get metricWeekSubtitle => '周一至周日';

  @override
  String metricMonthSubtitle(int month, String monthShort) {
    return '$month月总和';
  }

  @override
  String compactNumber(String tenThousands, String thousands) {
    return '$tenThousands万';
  }

  @override
  String get metricUnit => '声';

  @override
  String get calendarPrevMonth => '上一月';

  @override
  String get calendarNextMonth => '下一月';

  @override
  String calendarMonthTitle(int year, int month, String monthName) {
    return '$year 年 $month 月';
  }

  @override
  String get calendarToday => '今天';

  @override
  String get weekdaySun => '日';

  @override
  String get weekdayMon => '一';

  @override
  String get weekdayTue => '二';

  @override
  String get weekdayWed => '三';

  @override
  String get weekdayThu => '四';

  @override
  String get weekdayFri => '五';

  @override
  String get weekdaySat => '六';

  @override
  String calendarSelectedDate(int year, int month, int day, String monthName) {
    return '$year 年 $month 月 $day 日';
  }

  @override
  String get calendarTodayBadge => '今日';

  @override
  String get calendarEditButton => '修改数值';

  @override
  String get calendarCountUnit => '声佛号';

  @override
  String calendarBreakdown(int manual, int auto) {
    return '手动: $manual · 自动: $auto';
  }

  @override
  String get calendarGoalReached => '福慧圆满，共成佛道！';

  @override
  String get calendarGoalInProgress => '持续精进...';

  @override
  String get dailyGoalSheetTitle => '设定每日功课目标';

  @override
  String get dailyGoalRowTitle => '每日功课目标';

  @override
  String get dailyGoalRowSubtitle => '以当日手动 + 自动总声数计算达成';

  @override
  String dailyGoalValue(int count) {
    return '$count 声';
  }

  @override
  String get reminderTitle => '每日定时念佛提醒';

  @override
  String get reminderEnabledToast => '已开启每日定时提醒';

  @override
  String get reminderDisabledToast => '已关闭定时提醒';

  @override
  String reminderDailyAt(String time) {
    return '每天 $time 推送提醒';
  }

  @override
  String get reminderChangeTime => '更换时间';

  @override
  String get widgetCardTitle => 'iOS / Android 桌面小组件';

  @override
  String get widgetCardBody =>
      '支持桌面 Widget，随时在手机主屏幕查看今日精进、连续天数与每周累计。精进数据已自动实时同步。';

  @override
  String get widgetSyncedToast => '已同步最新数据至桌面小组件';

  @override
  String get widgetSyncNow => '立即同步桌面小组件';

  @override
  String get diagUnknown => '未知';

  @override
  String get diagNone => '无';

  @override
  String get diagReportTitle => '=== 桌面小组件诊断报告 ===';

  @override
  String diagPackageId(String pkg) {
    return '应用包名 (Package ID): $pkg';
  }

  @override
  String diagVersion(String ver) {
    return '应用版本 (Version): $ver';
  }

  @override
  String get diagCandidateGroups => '[候选 App Group 列表]';

  @override
  String get diagGroupData => '[各群组数据读取测试]';

  @override
  String get diagInstalledWidgets => '[系统已安装小组件]';

  @override
  String get diagNoWidgets => '无 (尚未检测到主屏幕已添加小组件)';

  @override
  String get diagDialogTitle => '小组件诊断信息';

  @override
  String get diagHint =>
      '💡 诊断提示：iOS 桌面小组件必须依赖 Apple 官方签名的 App Group 跨进程共享数据。若通过免费个人 Apple ID 经由 Sideloadly 侧载，Apple 会限制该权限导致小组件显示未连接；若使用付费开发者账号或 TestFlight 签名，则可完整实时同步。';

  @override
  String get diagCopiedToast => '已复制诊断报告至剪贴板';

  @override
  String get diagCopy => '复制报告';

  @override
  String get chantTagFourCharAmitabha => '四字弥陀';

  @override
  String get chantTagSixCharAmitabha => '六字弥陀';

  @override
  String get chantTagBodhisattvaMantra => '菩萨・持咒';

  @override
  String get chantTagPilgrimage => '朝山圣号';

  @override
  String get chantTagLingyan => '灵岩梵呗';

  @override
  String get chantTagMasterChant => '法师大德';

  @override
  String get chantTagBriskMedium => '快中板';

  @override
  String get chantTagSlowSolemn => '慢板';

  @override
  String get commonPlay => '播放';

  @override
  String get commonBack => '返回';

  @override
  String playerArtistAlbumBeat(String artist, String album, String seconds) {
    return '$artist · $album · 每拍 $seconds 秒';
  }

  @override
  String playerArtistBeat(String artist, String seconds) {
    return '$artist · 每拍 ${seconds}s';
  }

  @override
  String miniPlayerSubtitle(String artist, String seconds) {
    return '$artist · 每拍 ${seconds}s · 点击展开播放器';
  }

  @override
  String get playerLoopOne => '单曲循环';

  @override
  String get playerLoopList => '列表播放';

  @override
  String get playerPrevious => '上一首';

  @override
  String get playerNext => '下一首';

  @override
  String get playerRewind10 => '后退 10 秒';

  @override
  String get playerForward10 => '快进 10 秒';

  @override
  String playerSearchHint(int count) {
    return '搜索 $count 首佛曲名称...';
  }

  @override
  String songListAll(int count) {
    return '全部 ($count)';
  }

  @override
  String tagWithCount(String tag, int count) {
    return '$tag ($count)';
  }

  @override
  String get playerNoMatch => '无相符的佛曲';

  @override
  String get songMenuNoMatch => '无相符佛曲';

  @override
  String get songMenuExpand => '展开佛曲菜单';

  @override
  String get songMenuCollapse => '收起佛曲菜单';

  @override
  String songMenuHeaderExpanded(int count) {
    return '佛曲菜单（共 $count 首） · 点击收起';
  }

  @override
  String songMenuHeaderCollapsed(int count) {
    return '上滑展开佛曲菜单（共 $count 首）';
  }

  @override
  String get songMenuSearchHint => '搜索佛曲名称、法师或标签...';

  @override
  String get songMenuBackToPlayer => '收起回播放器';

  @override
  String songTileBeat(String seconds) {
    return '${seconds}s/拍';
  }

  @override
  String get legacySongListTitle => '佛曲清单';

  @override
  String get practiceBuddhaName => '南无阿弥陀佛';

  @override
  String get practiceBellToast => '合十回向 功德圆满';

  @override
  String get practiceBellButton => '引磬';

  @override
  String get huiXiangPrevTooltip => '上一则回向文';

  @override
  String get huiXiangNextTooltip => '下一则回向文';

  @override
  String get guideFeatureCountTitle => '念佛与自动计数';

  @override
  String guideFeatureCountDesc(int count) {
    return '全屏点击、引磬木鱼原音；或随 $count 首精选佛曲自动节拍计数。';
  }

  @override
  String get guideFeatureCalendarTitle => '每日功课表记';

  @override
  String get guideFeatureCalendarDesc => '最右侧月历随时查阅每天精进进度，支持自由手动修改增减。';

  @override
  String get guideFeatureWidgetTitle => '桌面小组件与定时提醒';

  @override
  String get guideFeatureWidgetDesc => '支持手机桌面 Widget 与每日定时念佛推送提醒，念念相续。';

  @override
  String get guideFeatureModeTitle => '现代与经典双风格';

  @override
  String get guideFeatureModeDesc => '右上角一键自由切换现代禅意与经典复古模式，修行更随心。';

  @override
  String get guideBadge => '全新升级重点';

  @override
  String get guideCloseTooltip => '关闭导览';

  @override
  String get guideTitle => '全新功能特色';

  @override
  String get guideSubtitle => '专为静心念佛与拜佛打造的精进伙伴';

  @override
  String get guideStart => '开始精进';

  @override
  String get aboutTitle => '阿忠小站';

  @override
  String get aboutAppName => '念佛计数器 (BuddhaCounter)';

  @override
  String aboutVersion(String version) {
    return '版本 $version';
  }

  @override
  String get aboutHeading => '【 阿忠小站 · 缘起与传承 】';

  @override
  String get aboutBody =>
      '本应用程序由李义忠（阿忠）居士发心设计开发，最初于 Android 早期发布，旨在提供十方念佛、拜佛同修一个方便、纯粹的随身精进记数工具。\n\n为使阿忠的心血得以长久传承、并服务更多现代修行大众，现由后辈工程师接棒维护，推出全新的操作界面。\n\n祈愿一切见闻者，皆发菩提心，一向专念南无阿弥陀佛，同生极乐国。';

  @override
  String get aboutVisitSite => '浏览阿忠小站 (https://www.leeyc.net)';

  @override
  String get aboutPrivacyIos => 'iOS 隐私政策';

  @override
  String get aboutPrivacyAndroid => 'Android 隐私政策';

  @override
  String get legacyAutoTitle => '念佛自动计数';

  @override
  String get legacyAutoSongButton => '念佛\n曲目';

  @override
  String get legacyTimerLabel => '计时：';

  @override
  String get legacyAudioLabel => '音频：';

  @override
  String get legacyAutoStopLabel => '自动关闭：';

  @override
  String get legacyMinutesLater => ' 分钟后';

  @override
  String get legacyResetZero => '归0';

  @override
  String get legacyChant => '念佛';

  @override
  String get legacyAudio => '音频';

  @override
  String get legacyChantTitle => '念佛页面';

  @override
  String get legacyBackHome => '返回首页';

  @override
  String get legacyUpgradeTitle => '念佛计数器 · 全新升级！';

  @override
  String get legacyUpgradeBody =>
      '已为您推出全新的「现代禅意模式」，包含沉浸圆环计数、自定义目标声数、随身佛曲播放器与昼夜护眼主题。\n\n您可随时切换体验，日后亦可自由切换回熟悉的经典模式。';

  @override
  String get legacyKeepClassic => '保留经典模式';

  @override
  String get legacyTryModern => '立即体验新版';

  @override
  String get legacyUnlockedToast => '已解除锁定';

  @override
  String get legacySwitchToModern => '切换至现代模式';

  @override
  String get switchedToModernToast => '已切换为现代模式';

  @override
  String get legacySettingsTitle => '设置';

  @override
  String get legacyCalendarMenu => '功课月历表记';

  @override
  String get legacyPreferences => '偏好设置';

  @override
  String get legacyGuideSubtitle => '了解现代禅意模式与新功能';

  @override
  String get legacyMinusOne => '减1';

  @override
  String get legacyDedicationPage => '回向页';

  @override
  String get legacyCounterPage => '计数页';

  @override
  String get legacyStop => '停止';

  @override
  String get legacySongs => '佛曲';

  @override
  String get legacyKeepScreenOnTitle => '保持屏幕常亮（防止休眠）';

  @override
  String get legacyKeepScreenOnDesc =>
      '开启后计数、念佛与播放佛曲时不会自动关闭屏幕，亦可直接于各页面顶部右上角快捷键切换';

  @override
  String get legacyClickSoundTitle => '点击计数音效';

  @override
  String get soundWoodfish1 => '木鱼一';

  @override
  String get soundWoodfish2 => '木鱼二 (经典原音)';

  @override
  String get soundBell => '引磬声';

  @override
  String get soundMute => '静音';

  @override
  String get legacyUiModeTitle => '界面模式切换';

  @override
  String get legacyClassicMode => '经典模式';

  @override
  String get legacyModernMode => '现代模式';

  @override
  String get legacySaveAndBack => '保存并返回';

  @override
  String widgetDate(int month, int day, String monthShort) {
    return '$month月$day日';
  }

  @override
  String widgetTargetText(int percent, int today, int target) {
    return '目标 $percent% ($today/$target)';
  }

  @override
  String widgetTodayNoGoal(int today) {
    return '今日累积 $today 声 (不限目标)';
  }

  @override
  String widgetStreak(int days) {
    return '🔥 连续 $days 天';
  }

  @override
  String get widgetStreakNone => '今日精进念佛';

  @override
  String widgetWeekly(int count) {
    return '本周: $count声';
  }

  @override
  String widgetMonthly(int count) {
    return '本月: $count声';
  }

  @override
  String get widgetRefresh => '刷新';

  @override
  String get reminderChannelName => '精进日课提醒';

  @override
  String get reminderChannelDesc => '简单的事情每天做，就会变成不简单。';

  @override
  String get reminderNotifTitle => '今日精进功课';

  @override
  String get reminderNotifBody => '开启念佛计数器填写今日功课数吧！';

  @override
  String get milestoneChannelName => '目标达成通知';

  @override
  String get milestoneChannelDesc => '发送目标达成与精进里程碑通知';

  @override
  String get audioChannelName => '念佛计数器佛曲播放';

  @override
  String get audioChannelDesc => '保持屏幕休眠或退至后台时佛曲持续播放';

  @override
  String mediaSubtitle(String artist, String album) {
    return '$artist · $album';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');
}
