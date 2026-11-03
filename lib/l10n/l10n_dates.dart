import 'package:intl/intl.dart';

/// 英文月份全名 (例如 November)，供英文日期句樣板的 `monthName` placeholder 使用。
/// 中文樣板不使用此值；`en` 的日期符號為 intl 內建，不需 initializeDateFormatting。
String englishMonthName(int month) =>
    DateFormat.MMMM('en').format(DateTime(2000, month));

/// 英文月份縮寫 (例如 Nov)
String englishMonthShort(int month) =>
    DateFormat.MMM('en').format(DateTime(2000, month));
