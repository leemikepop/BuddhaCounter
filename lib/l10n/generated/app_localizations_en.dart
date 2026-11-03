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

  @override
  String get calendarPrevYear => 'Previous year';

  @override
  String get calendarNextYear => 'Next year';

  @override
  String calendarYearLabel(int year) {
    return '$year';
  }

  @override
  String calendarMonthChip(int month, String monthShort) {
    return '$monthShort';
  }

  @override
  String get calendarBackToThisMonth => 'This month';

  @override
  String get calendarEditTitle => 'Edit practice count';

  @override
  String calendarEditDateLabel(int year, int month, int day, String monthName) {
    return 'Date: $monthName $day, $year';
  }

  @override
  String get calendarEditFieldLabel => 'Recitations';

  @override
  String get calendarEditFieldHint => 'Enter number of recitations';

  @override
  String get calendarEditSave => 'Save';

  @override
  String calendarEditSavedToast(int count) {
    return 'Updated to $count';
  }

  @override
  String get reminderPickerHelp => 'Daily reminder time';

  @override
  String reminderSetToast(String time) {
    return 'Daily reminder set for $time';
  }

  @override
  String streakBanner(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days-day streak',
      one: '1-day streak',
    );
    return '$_temp0';
  }

  @override
  String get streakBadge => 'On fire';

  @override
  String get streakEncourageActive =>
      'Keep the practice going — every recitation counts!';

  @override
  String get streakEncourageStart =>
      'Start today\'s first recitation and build a daily habit!';

  @override
  String get metricToday => 'Today';

  @override
  String get metricWeek => 'This week';

  @override
  String get metricMonth => 'This month';

  @override
  String metricTodayGoal(int goal, int percent) {
    return 'Goal $goal ($percent%)';
  }

  @override
  String get metricNoGoal => 'No goal';

  @override
  String get metricWeekSubtitle => 'Mon – Sun';

  @override
  String metricMonthSubtitle(int month, String monthShort) {
    return '$monthShort total';
  }

  @override
  String compactNumber(String tenThousands, String thousands) {
    return '${thousands}k';
  }

  @override
  String get metricUnit => '';

  @override
  String get calendarPrevMonth => 'Previous month';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String calendarMonthTitle(int year, int month, String monthName) {
    return '$monthName $year';
  }

  @override
  String get calendarToday => 'Today';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String calendarSelectedDate(int year, int month, int day, String monthName) {
    return '$monthName $day, $year';
  }

  @override
  String get calendarTodayBadge => 'Today';

  @override
  String get calendarEditButton => 'Edit';

  @override
  String get calendarCountUnit => 'recitations';

  @override
  String calendarBreakdown(int manual, int auto) {
    return 'Manual: $manual · Auto: $auto';
  }

  @override
  String get calendarGoalReached => 'Goal reached — may all attain Buddhahood!';

  @override
  String get calendarGoalInProgress => 'Keep going...';

  @override
  String get dailyGoalSheetTitle => 'Daily goal';

  @override
  String get dailyGoalRowTitle => 'Daily goal';

  @override
  String get dailyGoalRowSubtitle => 'Counts manual + auto recitations';

  @override
  String dailyGoalValue(int count) {
    return '$count';
  }

  @override
  String get reminderTitle => 'Daily reminder';

  @override
  String get reminderEnabledToast => 'Daily reminder on';

  @override
  String get reminderDisabledToast => 'Daily reminder off';

  @override
  String reminderDailyAt(String time) {
    return 'Every day at $time';
  }

  @override
  String get reminderChangeTime => 'Change';

  @override
  String get widgetCardTitle => 'Home screen widget';

  @override
  String get widgetCardBody =>
      'Add the widget to your home screen to see today\'s count, streak and weekly total. Data syncs automatically.';

  @override
  String get widgetSyncedToast => 'Widget updated';

  @override
  String get widgetSyncNow => 'Sync widget now';

  @override
  String get chantTagFourCharAmitabha => '4-char Amitabha';

  @override
  String get chantTagSixCharAmitabha => '6-char Amitabha';

  @override
  String get chantTagBodhisattvaMantra => 'Bodhisattvas & mantras';

  @override
  String get chantTagPilgrimage => 'Pilgrimage';

  @override
  String get chantTagLingyan => 'Lingyan chant';

  @override
  String get chantTagMasterChant => 'Masters';

  @override
  String get chantTagBriskMedium => 'Brisk';

  @override
  String get chantTagSlowSolemn => 'Slow';

  @override
  String get commonPlay => 'Play';

  @override
  String get commonBack => 'Back';

  @override
  String playerArtistAlbumBeat(String artist, String album, String seconds) {
    return '$artist · $album · ${seconds}s per beat';
  }

  @override
  String playerArtistBeat(String artist, String seconds) {
    return '$artist · ${seconds}s per beat';
  }

  @override
  String miniPlayerSubtitle(String artist, String seconds) {
    return '$artist · ${seconds}s per beat · tap to open';
  }

  @override
  String get playerLoopOne => 'Repeat one';

  @override
  String get playerLoopList => 'Play all';

  @override
  String get playerPrevious => 'Previous';

  @override
  String get playerNext => 'Next';

  @override
  String get playerRewind10 => 'Back 10 seconds';

  @override
  String get playerForward10 => 'Forward 10 seconds';

  @override
  String playerSearchHint(int count) {
    return 'Search $count chants...';
  }

  @override
  String songListAll(int count) {
    return 'All ($count)';
  }

  @override
  String tagWithCount(String tag, int count) {
    return '$tag ($count)';
  }

  @override
  String get playerNoMatch => 'No matching chants';

  @override
  String get songMenuNoMatch => 'No matching chants';

  @override
  String get songMenuExpand => 'Show chant list';

  @override
  String get songMenuCollapse => 'Hide chant list';

  @override
  String songMenuHeaderExpanded(int count) {
    return '$count chants · tap to collapse';
  }

  @override
  String songMenuHeaderCollapsed(int count) {
    return 'Swipe up for $count chants';
  }

  @override
  String get songMenuSearchHint => 'Search title, master or tag...';

  @override
  String get songMenuBackToPlayer => 'Back to player';

  @override
  String songTileBeat(String seconds) {
    return '${seconds}s/beat';
  }

  @override
  String get legacySongListTitle => 'Chant list';

  @override
  String get practiceBuddhaName => 'Namo Amitabha Buddha';

  @override
  String get practiceBellToast => 'Merit dedicated — may it be complete';

  @override
  String get practiceBellButton => 'Bell';

  @override
  String get huiXiangPrevTooltip => 'Previous dedication';

  @override
  String get huiXiangNextTooltip => 'Next dedication';

  @override
  String get guideFeatureCountTitle => 'Recitation & auto count';

  @override
  String guideFeatureCountDesc(int count) {
    return 'Tap anywhere with bell or wooden-fish sounds, or count automatically with $count selected chants.';
  }

  @override
  String get guideFeatureCalendarTitle => 'Daily practice log';

  @override
  String get guideFeatureCalendarDesc =>
      'Check each day\'s progress in the Calendar tab and edit counts anytime.';

  @override
  String get guideFeatureWidgetTitle => 'Widget & daily reminder';

  @override
  String get guideFeatureWidgetDesc =>
      'Home screen widget and a daily reminder keep your practice going.';

  @override
  String get guideFeatureModeTitle => 'Zen & Classic styles';

  @override
  String get guideFeatureModeDesc =>
      'Switch between Zen and Classic mode from the top-right corner.';

  @override
  String get guideBadge => 'What\'s new';

  @override
  String get guideCloseTooltip => 'Close guide';

  @override
  String get guideTitle => 'New features';

  @override
  String get guideSubtitle =>
      'A companion for mindful recitation and prostration';

  @override
  String get guideStart => 'Get started';

  @override
  String get aboutTitle => 'A-Chung\'s Corner';

  @override
  String get aboutAppName => 'Buddha Counter';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutHeading => 'Our story';

  @override
  String get aboutBody =>
      'This app was created by lay practitioner Lee Yi-Chung (A-Chung) and first released in the early days of Android, to give fellow practitioners a simple, pure companion for counting recitations and prostrations.\n\nTo carry on A-Chung\'s work and serve more practitioners today, it is now maintained by a younger engineer with a brand-new interface.\n\nMay all who see or hear of this arouse the Bodhi mind, single-mindedly recite Namo Amitabha Buddha, and together be reborn in the Land of Ultimate Bliss.';

  @override
  String get aboutVisitSite =>
      'Visit A-Chung\'s Corner (https://www.leeyc.net)';

  @override
  String get aboutPrivacyIos => 'iOS privacy policy';

  @override
  String get aboutPrivacyAndroid => 'Android privacy policy';

  @override
  String get legacyAutoTitle => 'Auto count';

  @override
  String get legacyAutoSongButton => 'Chant\nlist';

  @override
  String get legacyTimerLabel => 'Time: ';

  @override
  String get legacyAudioLabel => 'Audio: ';

  @override
  String get legacyAutoStopLabel => 'Stop in: ';

  @override
  String get legacyMinutesLater => ' min';

  @override
  String get legacyResetZero => 'Reset';

  @override
  String get legacyChant => 'Chant';

  @override
  String get legacyAudio => 'Audio';

  @override
  String get legacyChantTitle => 'Recitation';

  @override
  String get legacyBackHome => 'Home';

  @override
  String get legacyUpgradeTitle => 'Buddha Counter · What\'s new!';

  @override
  String get legacyUpgradeBody =>
      'Introducing the new Zen mode: an immersive ring counter, custom goals, a built-in chant player and light/dark themes.\n\nTry it anytime — you can always switch back to Classic mode.';

  @override
  String get legacyKeepClassic => 'Keep Classic';

  @override
  String get legacyTryModern => 'Try Zen mode';

  @override
  String get legacyUnlockedToast => 'Orientation unlocked';

  @override
  String get legacySwitchToModern => 'Switch to Zen mode';

  @override
  String get switchedToModernToast => 'Switched to Zen mode';

  @override
  String get legacySettingsTitle => 'Settings';

  @override
  String get legacyCalendarMenu => 'Practice calendar';

  @override
  String get legacyPreferences => 'Preferences';

  @override
  String get legacyGuideSubtitle => 'Learn about Zen mode and new features';

  @override
  String get legacyMinusOne => '−1';

  @override
  String get legacyDedicationPage => 'Dedication';

  @override
  String get legacyCounterPage => 'Counter';

  @override
  String get legacyStop => 'Stop';

  @override
  String get legacySongs => 'Chants';

  @override
  String get legacyKeepScreenOnTitle => 'Keep screen on';

  @override
  String get legacyKeepScreenOnDesc =>
      'The screen stays on while counting or playing chants. You can also toggle this from the top-right of each page.';

  @override
  String get legacyClickSoundTitle => 'Tap sound';

  @override
  String get soundWoodfish1 => 'Wooden fish 1';

  @override
  String get soundWoodfish2 => 'Wooden fish 2 (classic)';

  @override
  String get soundBell => 'Hand bell';

  @override
  String get soundMute => 'Mute';

  @override
  String get legacyUiModeTitle => 'Interface style';

  @override
  String get legacyClassicMode => 'Classic mode';

  @override
  String get legacyModernMode => 'Zen mode';

  @override
  String get legacySaveAndBack => 'Save and go back';

  @override
  String widgetDate(int month, int day, String monthShort) {
    return '$monthShort $day';
  }

  @override
  String widgetTargetText(int percent, int today, int target) {
    return 'Goal $percent% ($today/$target)';
  }

  @override
  String widgetTodayNoGoal(int today) {
    return 'Today: $today (no goal)';
  }

  @override
  String widgetStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '🔥 $days-day streak',
      one: '🔥 1-day streak',
    );
    return '$_temp0';
  }

  @override
  String get widgetStreakNone => 'Practice today';

  @override
  String widgetWeekly(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Week: $countString';
  }

  @override
  String widgetMonthly(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Month: $countString';
  }

  @override
  String get widgetRefresh => 'Refresh';

  @override
  String get reminderChannelName => 'Daily practice reminder';

  @override
  String get reminderChannelDesc =>
      'Small things done every day become something great.';

  @override
  String get reminderNotifTitle => 'Today\'s practice';

  @override
  String get reminderNotifBody =>
      'Open Buddha Counter and log today\'s practice!';

  @override
  String get milestoneChannelName => 'Goals & milestones';

  @override
  String get milestoneChannelDesc =>
      'Notifications when you reach goals and milestones';

  @override
  String get audioChannelName => 'Buddha Counter chant playback';

  @override
  String get audioChannelDesc =>
      'Keeps chants playing with the screen off or in the background';

  @override
  String mediaSubtitle(String artist, String album) {
    return '$artist · $album';
  }
}
