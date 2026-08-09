import 'package:flutter/material.dart';

/// "სამეფო ზეთისხილისფერი" — the deep emerald felt + antique gold
/// identity picked (of 3 mockup directions) for the whole app: the
/// Scaffold background reads as the card table itself, physical cards
/// (see PlayingCardWidget) sit on it as cream parchment, and gold marks
/// anything interactive.
class KingColors {
  KingColors._();

  static const feltDark = Color(0xFF072A20);
  static const felt = Color(0xFF0C3D2E);
  static const feltLight = Color(0xFF14523F);

  static const gold = Color(0xFFC9A34E);
  static const goldLight = Color(0xFFE0BD72);

  static const cream = Color(0xFFF6EFE0);
  static const creamMuted = Color(0xFFD8D2C4);

  static const inkNavy = Color(0xFF1C2340);
  static const brickRed = Color(0xFF8C2F39);

  /// Cream text/icons at reduced opacity, for secondary copy sitting
  /// directly on the felt background — replaces the Colors.black54/38/26
  /// this app used before, which all assumed a light background.
  static const onFeltSoft = Color(0xB3F6EFE0); // ~70% cream
  static const onFeltFaint = Color(0x80F6EFE0); // ~50% cream
  static const onFeltHairline = Color(0x40F6EFE0); // ~25% cream
}

ThemeData buildKingTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: KingColors.gold,
    onPrimary: KingColors.inkNavy,
    secondary: KingColors.brickRed,
    onSecondary: KingColors.cream,
    error: Color(0xFFCF6679),
    onError: KingColors.inkNavy,
    surface: KingColors.feltLight,
    onSurface: KingColors.cream,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: KingColors.felt,
    appBarTheme: const AppBarTheme(
      backgroundColor: KingColors.feltDark,
      foregroundColor: KingColors.cream,
      elevation: 0,
    ),
    textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: KingColors.cream,
          displayColor: KingColors.cream,
        ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: KingColors.gold,
        foregroundColor: KingColors.inkNavy,
        disabledBackgroundColor: KingColors.gold.withValues(alpha: 0.35),
        disabledForegroundColor: KingColors.inkNavy.withValues(alpha: 0.6),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: KingColors.cream,
        side: const BorderSide(color: KingColors.gold),
      ),
    ),
    // The only TextButton in the app is the "cancel" action inside the
    // leave-confirmation AlertDialog, which (per dialogTheme below) has
    // a cream background — so this needs dark ink, not the cream used
    // for buttons that sit directly on the felt.
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: KingColors.inkNavy),
    ),
    cardTheme: const CardThemeData(
      color: KingColors.cream,
      elevation: 2,
      surfaceTintColor: Colors.transparent,
    ),
    listTileTheme: const ListTileThemeData(
      textColor: KingColors.inkNavy,
      iconColor: KingColors.inkNavy,
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: KingColors.feltLight,
      selectedColor: KingColors.gold,
      labelStyle: TextStyle(color: KingColors.cream),
      secondaryLabelStyle: TextStyle(color: KingColors.inkNavy),
      side: BorderSide(color: KingColors.gold),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: KingColors.gold),
    dialogTheme: const DialogThemeData(
      backgroundColor: KingColors.cream,
      titleTextStyle: TextStyle(color: KingColors.inkNavy, fontSize: 20, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: KingColors.inkNavy, fontSize: 15),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: KingColors.feltDark,
      contentTextStyle: TextStyle(color: KingColors.cream),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      labelStyle: TextStyle(color: KingColors.onFeltSoft),
      hintStyle: TextStyle(color: KingColors.onFeltFaint),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: KingColors.onFeltHairline)),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: KingColors.gold, width: 2)),
    ),
    dividerTheme: const DividerThemeData(color: KingColors.onFeltHairline),
  );
}
