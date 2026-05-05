import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(
          bodyColor: const Color(AppColors.dark),
          displayColor: const Color(AppColors.dark),
        );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(AppColors.bg),
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: Color(AppColors.primary),
        secondary: Color(AppColors.primary),
        surface: Color(AppColors.surface),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(AppColors.bg),
        foregroundColor: Color(AppColors.dark),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(AppColors.dark),
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.4,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(AppColors.line),
        thickness: 1,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shadowColor: Color(0x200C1424),
        color: Color(AppColors.surface),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FBFF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: TextStyle(
          color: const Color(AppColors.muted).withValues(alpha: 0.7),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        labelStyle: TextStyle(
          color: const Color(AppColors.muted).withValues(alpha: 0.85),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(AppColors.line)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(AppColors.line),
            width: 1.1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(AppColors.primary),
            width: 1.3,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide.none,
        selectedColor: const Color(AppColors.primary).withValues(alpha: 0.2),
        backgroundColor: const Color(AppColors.chip),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(AppColors.surface),
        indicatorColor: const Color(AppColors.primary).withValues(alpha: 0.16),
        elevation: 0,
        shadowColor: const Color(0x100E172E),
        indicatorShape: const StadiumBorder(),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: states.contains(WidgetState.selected)
                ? const Color(AppColors.primary)
                : const Color(AppColors.muted),
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 19,
            color: states.contains(WidgetState.selected)
                ? const Color(AppColors.primary)
                : const Color(AppColors.dark),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(AppColors.primary),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: Color(AppColors.line)),
          foregroundColor: const Color(AppColors.dark),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(AppColors.dark),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(AppColors.bg),
        surfaceTintColor: Colors.transparent,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(
          bodyColor: const Color(0xFFF3F7FF),
          displayColor: const Color(0xFFF3F7FF),
        );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF09111F),
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(AppColors.primary),
        secondary: Color(AppColors.primary),
        surface: Color(0xFF101A2D),
        onSurface: Color(0xFFF3F7FF),
        onPrimary: Colors.white,
        outline: Color(0xFF2B3952),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF09111F),
        foregroundColor: Color(0xFFF3F7FF),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFFF3F7FF),
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.4,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF24324B),
        thickness: 1,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shadowColor: Color(0x40000000),
        color: Color(0xFF101A2D),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111E34),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF92A0BC),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        labelStyle: const TextStyle(
          color: Color(0xFFB4C0D7),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF24324B)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF24324B), width: 1.1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(AppColors.primary),
            width: 1.3,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide.none,
        selectedColor: const Color(AppColors.primary).withValues(alpha: 0.25),
        backgroundColor: const Color(0xFF15243A),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF101A2D),
        indicatorColor: const Color(AppColors.primary).withValues(alpha: 0.22),
        elevation: 0,
        shadowColor: const Color(0x66000000),
        indicatorShape: const StadiumBorder(),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: states.contains(WidgetState.selected)
                ? const Color(AppColors.primary)
                : const Color(0xFF9AA6BE),
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 19,
            color: states.contains(WidgetState.selected)
                ? const Color(AppColors.primary)
                : const Color(0xFFE8EEF9),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(AppColors.primary),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: Color(0xFF24324B)),
          foregroundColor: const Color(0xFFF3F7FF),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFF3F7FF),
        contentTextStyle: const TextStyle(
          color: Color(0xFF09111F),
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF09111F),
        surfaceTintColor: Colors.transparent,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
