import 'package:flutter/material.dart';

/// 現代禪意風格設計系統配色與主題規範
class ModernTheme {
  // --- 淺色模式：宣紙暖白 · 沉香金木 (Warm Zen Light) ---
  static const Color lightBg = Color(0xFFFAF7F2);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF5EFE6);
  static const Color lightCardBorder = Color(0xFFEBE3D5);
  static const Color lightPrimary = Color(0xFF8C5E32); // 沉木棕
  static const Color lightAccent = Color(0xFFC59F54);  // 沉香金
  static const Color lightTextPrimary = Color(0xFF2C2825); // 墨黑
  static const Color lightTextSecondary = Color(0xFF756F68); // 淡墨灰
  static const Color lightDivider = Color(0xFFEBE4D8);

  // --- 深色模式：幽夜極靜 · 沉檀古金 (Deep Night Zen Dark) ---
  static const Color darkBg = Color(0xFF131418);
  static const Color darkSurface = Color(0xFF1B1C22);
  static const Color darkCard = Color(0xFF22242B);
  static const Color darkCardBorder = Color(0xFF2E313A);
  static const Color darkPrimary = Color(0xFFDDB66B); // 幽夜暖金
  static const Color darkAccent = Color(0xFFBA9E6E);
  static const Color darkTextPrimary = Color(0xFFF3F1EC); // 玉白
  static const Color darkTextSecondary = Color(0xFFA3A199); // 銀灰
  static const Color darkDivider = Color(0xFF2A2D36);

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: lightPrimary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFF3E7D8),
      onPrimaryContainer: Color(0xFF4A3215),
      secondary: lightAccent,
      onSecondary: Colors.white,
      surface: lightSurface,
      onSurface: lightTextPrimary,
      surfaceContainerLowest: lightBg,
      surfaceContainerLow: lightCard,
      surfaceContainer: Color(0xFFEFE8DC),
      outline: lightCardBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: lightTextPrimary,
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightCardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurface,
        elevation: 8,
        indicatorColor: const Color(0xFFF3E7D8),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: lightPrimary);
          }
          return const IconThemeData(color: lightTextSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: lightPrimary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: lightTextSecondary,
          );
        }),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: lightPrimary,
        inactiveTrackColor: Color(0xFFE5DDD0),
        thumbColor: lightPrimary,
        overlayColor: Color(0x298C5E32),
        trackHeight: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: lightDivider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: darkPrimary,
      onPrimary: Color(0xFF241A08),
      primaryContainer: Color(0xFF382E1E),
      onPrimaryContainer: Color(0xFFF7E7CD),
      secondary: darkAccent,
      onSecondary: Color(0xFF241A08),
      surface: darkSurface,
      onSurface: darkTextPrimary,
      surfaceContainerLowest: darkBg,
      surfaceContainerLow: darkCard,
      surfaceContainer: Color(0xFF292C35),
      outline: darkCardBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: darkTextPrimary,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkCardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        elevation: 8,
        indicatorColor: const Color(0xFF382E1E),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: darkPrimary);
          }
          return const IconThemeData(color: darkTextSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: darkPrimary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: darkTextSecondary,
          );
        }),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: darkPrimary,
        inactiveTrackColor: Color(0xFF3A3E4B),
        thumbColor: darkPrimary,
        overlayColor: Color(0x29DDB66B),
        trackHeight: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
