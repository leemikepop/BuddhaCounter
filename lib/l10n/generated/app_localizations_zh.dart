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
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');
}
