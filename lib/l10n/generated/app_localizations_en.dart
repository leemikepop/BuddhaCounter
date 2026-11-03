// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Buddha Counter';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonSet => 'Set';

  @override
  String get commonClose => 'Close';

  @override
  String get languageMenuTitle => 'Language';

  @override
  String get languageFollowSystem => 'System default';

  @override
  String get commonStart => 'Start';

  @override
  String get commonPause => 'Pause';

  @override
  String get tabManual => 'Manual';

  @override
  String get tabAuto => 'Auto';

  @override
  String get tabDedication => 'Dedication';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String get themeSwitchedLightToast => 'Light mode on';

  @override
  String get themeSwitchedDarkToast => 'Dark mode on';

  @override
  String get themeToLightTooltip => 'Switch to light mode';

  @override
  String get themeToDarkTooltip => 'Switch to dark mode';

  @override
  String get orientationUnlockTooltip => 'Unlock orientation';

  @override
  String get orientationLockTooltip => 'Lock orientation';

  @override
  String get orientationLockedToast => 'Orientation locked';

  @override
  String get orientationUnlockedToast => 'Orientation unlocked';

  @override
  String get screenAwakeOn => 'Keep screen on';

  @override
  String get screenAwakeOffTooltip => 'Allow screen to sleep';

  @override
  String get screenAwakeOffToast => 'Screen may sleep';

  @override
  String get switchToClassicMode => 'Switch to Classic mode';

  @override
  String get switchedToClassicToast => 'Switched to Classic mode';

  @override
  String get drawerHeaderTitle => 'Buddha Counter';

  @override
  String get drawerHeaderSubtitle => 'Namo Amitabha Buddha';

  @override
  String get drawerSongList => 'Choose a chant';

  @override
  String get drawerGuide => 'Feature guide';

  @override
  String get drawerAbout => 'About · A-Chung\'s Corner';

  @override
  String get counterResetConfirmTitle => 'Reset the count?';

  @override
  String counterResetConfirmBody(int count) {
    return 'Current count: $count';
  }

  @override
  String get counterResetConfirmAction => 'Reset';

  @override
  String get counterResetDoneToast => 'Count reset';

  @override
  String get manualGoalSheetTitle => 'Manual count goal';

  @override
  String get timerResetTooltip => 'Reset timer';

  @override
  String goalChipLabel(int count) {
    return 'Goal $count';
  }

  @override
  String get goalChipUnlimited => 'No goal';

  @override
  String get counterMinusOne => '−1';

  @override
  String get counterResetShort => 'Reset';

  @override
  String get soundEffectTitle => 'Sound';

  @override
  String get soundChipWoodfish1 => 'Fish 1';

  @override
  String get soundChipWoodfish2 => 'Fish 2';

  @override
  String get soundChipBell => 'Bell';

  @override
  String get soundChipMute => 'Mute';

  @override
  String get vibrationFeedback => 'Haptics';

  @override
  String get fullscreenTap => 'Tap anywhere';

  @override
  String get zenCircleUnitLabel => 'recitations · bows';

  @override
  String goalProgressLabel(int count, int percent) {
    return 'Goal $count · $percent%';
  }

  @override
  String goalReachedLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Reached $count recitations',
      one: 'Reached 1 recitation',
    );
    return '$_temp0';
  }

  @override
  String get goalUnlimited => 'No goal';

  @override
  String goalCustomChip(int value) {
    return '$value (custom)';
  }

  @override
  String get goalCustomPrompt => 'Or enter a custom goal:';

  @override
  String get goalCustomHint => 'Goal (e.g. 500)';

  @override
  String get unitRecitationsSuffix => 'times';

  @override
  String get goalInvalidNumber => 'Enter a number greater than 0';

  @override
  String get goalSetUnlimitedToast => 'Goal removed';

  @override
  String goalSetToast(int count) {
    return 'Goal set: $count';
  }

  @override
  String get autoStopSheetTitle => 'Auto stop';

  @override
  String get autoStopExclusiveHint =>
      'Choose either a count or a time. Setting one clears the other.';

  @override
  String get autoStopByCountTitle => 'Stop after a count';

  @override
  String get autoStopByTimeTitle => 'Stop after a time';

  @override
  String autoCountChip(int count) {
    return '$count';
  }

  @override
  String autoCountCustomChip(int count) {
    return '$count (custom)';
  }

  @override
  String autoCountGoalSetToast(int count) {
    return 'Will stop after $count';
  }

  @override
  String get autoCountGoalClearedToast => 'Count goal removed';

  @override
  String autoMinutesChip(int minutes) {
    return '$minutes min';
  }

  @override
  String autoMinutesCustomChip(int minutes) {
    return '$minutes min (custom)';
  }

  @override
  String get autoMinutesPrompt => 'Or enter custom minutes:';

  @override
  String get autoMinutesHint => 'Minutes (e.g. 20)';

  @override
  String get unitMinutesSuffix => 'min';

  @override
  String get autoMinutesInvalid => 'Enter minutes greater than 0';

  @override
  String autoTimerSetToast(int minutes) {
    return 'Will stop after $minutes min';
  }

  @override
  String get autoTimerClearedToast => 'Timer removed';

  @override
  String get autoStopClearAction => 'Clear and play continuously';

  @override
  String get autoStopClearedToast => 'Playing continuously';

  @override
  String get autoAlreadyZeroToast => 'Count is already 0';

  @override
  String get autoResetConfirmTitle => 'Reset auto count?';

  @override
  String autoResetConfirmBody(int count) {
    return 'Reset the auto count of $count to 0?\n(The timer will be kept.)';
  }

  @override
  String get autoResetConfirmAction => 'Reset';

  @override
  String get autoResetDoneToast => 'Auto count reset to 0';

  @override
  String get autoTimerResetToast => 'Timer reset';

  @override
  String autoTimeProgressLabel(int minutes, String remaining) {
    return 'Timer $minutes min · $remaining left';
  }

  @override
  String autoTimeReachedLabel(int minutes) {
    return 'Timer $minutes min · done';
  }

  @override
  String autoTimerChip(int minutes) {
    return '$minutes min';
  }

  @override
  String get autoContinuous => 'Continuous';

  @override
  String get autoCircleUnitLabel => 'recitations';

  @override
  String autoBeatHint(String seconds) {
    return '+1 every ${seconds}s';
  }

  @override
  String get autoResetShort => 'Reset';

  @override
  String autoRemainingMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String autoRemainingSeconds(int seconds) {
    return '$seconds s';
  }
}
