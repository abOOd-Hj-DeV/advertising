import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class Brand {
  static const green = Color(0xff2f6812);
  static const deep = Color(0xff234d07);
  static const lime = Color(0xffb4e934);
  static const pale = Color(0xffe9f7c4);
  static const background = Color(0xfff4f3f0);
  static const muted = Color(0xff7a7973);
  static const line = Color(0xffddddd7);
  static ThemeData theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: green,
      brightness: brightness,
      primary: dark ? const Color(0xffb4e934) : green,
      surface: dark ? const Color(0xff1c1d1a) : Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'NunitoSans',
      fontFamilyFallback: kIsWeb ? const ['LocalFallback'] : null,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      dividerColor: dark ? const Color(0xff41433c) : line,
      textTheme: ThemeData(
        brightness: brightness,
      ).textTheme.apply(fontFamily: 'NunitoSans'),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          fontFamily: 'NunitoSans',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: dark ? const Color(0xff41433c) : line,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Brand.muted),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Brand.muted),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: lime,
          foregroundColor: deep,
          minimumSize: const Size(double.infinity, 48),
          textStyle: const TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? green
              : const Color(0xff999a91),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
