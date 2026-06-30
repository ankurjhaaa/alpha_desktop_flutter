import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class AppTheme {
  static const double borderRadius = 8.0;

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0D47A1),
      primary: const Color(0xFF0D47A1), // Force pure deep blue
      brightness: Brightness.light,
      surface: Colors.white,
      surfaceContainerHighest: const Color(0xFFE2E8F0),
      onSurface: const Color(0xFF0F172A),
    ),
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    cardColor: Colors.white,
    dialogBackgroundColor: Colors.white,
    dividerColor: const Color(0xFFE2E8F0),
    dataTableTheme: const DataTableThemeData(
      dataRowMinHeight: 48,
      dataRowMaxHeight: 120,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
      displayLarge: GoogleFonts.inter(color: const Color(0xFF0F172A)),
      displayMedium: GoogleFonts.inter(color: const Color(0xFF0F172A)),
      displaySmall: GoogleFonts.inter(color: const Color(0xFF0F172A)),
      headlineLarge: GoogleFonts.inter(color: const Color(0xFF0F172A)),
      headlineMedium: GoogleFonts.inter(color: const Color(0xFF0F172A)),
      headlineSmall: GoogleFonts.inter(color: const Color(0xFF0F172A)),
      titleLarge: GoogleFonts.inter(color: const Color(0xFF0F172A), fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.inter(color: const Color(0xFF0F172A), fontWeight: FontWeight.w600),
      titleSmall: GoogleFonts.inter(color: const Color(0xFF0F172A), fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.inter(color: const Color(0xFF334155)),
      bodyMedium: GoogleFonts.inter(color: const Color(0xFF475569)),
      bodySmall: GoogleFonts.inter(color: const Color(0xFF64748B)),
      labelLarge: GoogleFonts.inter(color: const Color(0xFF475569)),
      labelMedium: GoogleFonts.inter(color: const Color(0xFF64748B)),
      labelSmall: GoogleFonts.inter(color: const Color(0xFF64748B)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: NoTransitionsBuilder(),
        TargetPlatform.iOS: NoTransitionsBuilder(),
        TargetPlatform.macOS: NoTransitionsBuilder(),
        TargetPlatform.windows: NoTransitionsBuilder(),
        TargetPlatform.linux: NoTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      titleTextStyle: GoogleFonts.inter(
        color: const Color(0xFF0F172A),
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: Brightness.dark,
      surface: const Color(0xFF1E293B),
      surfaceContainerHighest: const Color(0xFF334155),
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFF1E293B),
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: Color(0xFF1E293B),
      surfaceTintColor: Colors.transparent,
    ),
    cardColor: const Color(0xFF1E293B),
    dialogBackgroundColor: const Color(0xFF1E293B),
    dividerColor: const Color(0xFF334155),
    dataTableTheme: const DataTableThemeData(
      dataRowMinHeight: 48,
      dataRowMaxHeight: 120,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: NoTransitionsBuilder(),
        TargetPlatform.iOS: NoTransitionsBuilder(),
        TargetPlatform.macOS: NoTransitionsBuilder(),
        TargetPlatform.windows: NoTransitionsBuilder(),
        TargetPlatform.linux: NoTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E293B),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: const BorderSide(color: Color(0xFF334155), width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E293B),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    ),
  );
}
