import 'package:material_ui/material_ui.dart';

/// Warm, editorial visual language inspired by modern profile-led social apps.
class AppTheme {
  static const Color ink = Color(0xFF20211E);
  static const Color sunshine = Color(0xFFFFCB45);
  static const Color sage = Color(0xFF8EAA69);
  static const Color coral = Color(0xFFE9826C);
  static const Color cream = Color(0xFFFFFAF1);
  static const Color paper = Color(0xFFFFFFFF);
  static const Color line = Color(0xFFE9E1D5);
  static const Color mutedInk = Color(0xFF746F66);

  // Existing feature accents, retained for widgets that describe these actions.
  static const Color chatBlue = ink;
  static const Color verifyGreen = sage;
  static const Color meetYellow = sunshine;
  static const Color compatiblePink = coral;

  static const Color darkBg = Color(0xFF171815);
  static const Color darkCard = Color(0xFF23241F);
  static const Color darkBorder = Color(0xFF383A32);
  static const Color lightBg = cream;
  static const Color lightCard = paper;
  static const Color lightBorder = line;

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: sunshine,
        selectionColor: Color(0x66FFCB45),
        selectionHandleColor: sunshine,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: cream,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: cream),
      ),
      colorScheme: const ColorScheme.dark(
        primary: sunshine,
        secondary: sage,
        tertiary: coral,
        surface: darkCard,
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
          backgroundColor: sunshine,
          foregroundColor: ink,
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      inputDecorationTheme: _inputDecorationTheme(
        fill: darkCard,
        label: const Color(0xFFB9B8B1),
        border: darkBorder,
        focus: sunshine,
      ),
    );
  }

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: cream,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: ink,
        selectionColor: Color(0x66FFCB45),
        selectionHandleColor: ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ink),
      ),
      colorScheme: const ColorScheme.light(
        primary: ink,
        secondary: sunshine,
        tertiary: coral,
        surface: paper,
        onSurface: ink,
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(color: ink, fontWeight: FontWeight.w900, letterSpacing: -1.1),
        headlineSmall: TextStyle(color: ink, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(color: ink, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: ink),
        bodyMedium: TextStyle(color: ink),
        labelMedium: TextStyle(color: mutedInk),
      ),
      cardTheme: CardThemeData(
        color: paper,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: line),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
          backgroundColor: ink,
          foregroundColor: paper,
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 48),
          foregroundColor: ink,
          side: const BorderSide(color: line, width: 1.4),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: _inputDecorationTheme(
        fill: paper,
        label: mutedInk,
        border: line,
        focus: ink,
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1),
    );
  }

  static InputDecorationTheme _inputDecorationTheme({
    required Color fill,
    required Color label,
    required Color border,
    required Color focus,
  }) {
    OutlineInputBorder outline(Color color, {double width = 1}) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: TextStyle(color: label),
      floatingLabelStyle: TextStyle(color: focus, fontWeight: FontWeight.w700),
      border: outline(border),
      enabledBorder: outline(border),
      focusedBorder: outline(focus, width: 1.8),
      errorBorder: outline(const Color(0xFFBD4334)),
      focusedErrorBorder: outline(const Color(0xFFBD4334), width: 1.8),
    );
  }
}
