import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_base.dart';
import 'package:tiamat/config/style/theme_extensions.dart';

/// Nord theme based on arcticicestudio's color palette
class ThemeNordColors {
  // Polar Night
  static const Color nord0 = Color(0xFF2e3440);
  static const Color nord1 = Color(0xFF3b4252);
  static const Color nord2 = Color(0xFF434c5e);
  static const Color nord3 = Color(0xFF4c566a);
  // Snow Storm
  static const Color nord4 = Color(0xFFd8dee9);
  static const Color nord5 = Color(0xFFe5e9f0);
  static const Color nord6 = Color(0xFFeceff4);
  // Frost
  static const Color nord7 = Color(0xFF8fbcbb);
  static const Color nord8 = Color(0xFF88c0d0);
  static const Color nord9 = Color(0xFF81a1c1);
  static const Color nord10 = Color(0xFF5e81ac);
  // Aurora
  static const Color nord11 = Color(0xFFbf616a);
  static const Color nord12 = Color(0xFFd08770);
  static const Color nord13 = Color(0xFFebcb8b);
  static const Color nord14 = Color(0xFFa3be8c);
  static const Color nord15 = Color(0xFFb48ead);
}

class ThemeNord {
  static ThemeData get theme {
    var scheme = ColorScheme.fromSeed(
      seedColor: ThemeNordColors.nord0,
      dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
      primary: ThemeNordColors.nord8,
      onPrimary: ThemeNordColors.nord0,
      surface: ThemeNordColors.nord0,
      surfaceContainer: ThemeNordColors.nord1,
      surfaceContainerLow: Color(0xFF252b37),
      surfaceContainerLowest: Color(0xFF1d2330),
      primaryContainer: ThemeNordColors.nord9,
      brightness: Brightness.dark,
      outline: ThemeNordColors.nord2,
      error: ThemeNordColors.nord11,
      secondary: ThemeNordColors.nord3,
      onSurface: ThemeNordColors.nord4,
    );

    return ThemeBase.theme(scheme).copyWith(extensions: [
      const ThemeSettings(caulkBorders: true, caulkBorderRadius: 1),
      const ExtraColors(
        codeHighlight: ThemeNordColors.nord15,
        linkColor: ThemeNordColors.nord8,
      ),
    ]);
  }
}
