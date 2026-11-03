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
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');
}
