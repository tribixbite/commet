import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tiamat/config/style/theme_base.dart';
import 'package:tiamat/config/style/theme_extensions.dart';

/// Solarized Dark theme based on Ethan Schoonover's color scheme
class ThemeSolarizedColors {
  static const Color base03 = Color(0xFF002b36);
  static const Color base02 = Color(0xFF073642);
  static const Color base01 = Color(0xFF586e75);
  static const Color base00 = Color(0xFF657b83);
  static const Color base0 = Color(0xFF839496);
  static const Color base1 = Color(0xFF93a1a1);
  static const Color base2 = Color(0xFFeee8d5);
  static const Color base3 = Color(0xFFfdf6e3);
  static const Color yellow = Color(0xFFb58900);
  static const Color orange = Color(0xFFcb4b16);
  static const Color red = Color(0xFFdc322f);
  static const Color magenta = Color(0xFFd33682);
  static const Color violet = Color(0xFF6c71c4);
  static const Color blue = Color(0xFF268bd2);
  static const Color cyan = Color(0xFF2aa198);
  static const Color green = Color(0xFF859900);
}

class ThemeSolarized {
  static ThemeData get theme {
    var scheme = ColorScheme.fromSeed(
      seedColor: ThemeSolarizedColors.base03,
      dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
      primary: ThemeSolarizedColors.blue,
      onPrimary: ThemeSolarizedColors.base3,
      surface: ThemeSolarizedColors.base03,
      surfaceContainer: ThemeSolarizedColors.base02,
      surfaceContainerLow: Color(0xFF001f27),
      surfaceContainerLowest: Color(0xFF00141c),
      primaryContainer: ThemeSolarizedColors.blue,
      brightness: Brightness.dark,
      outline: ThemeSolarizedColors.base02,
      error: ThemeSolarizedColors.red,
      secondary: ThemeSolarizedColors.base01,
      onSurface: ThemeSolarizedColors.base0,
    );

    return ThemeBase.theme(scheme).copyWith(extensions: [
      const ThemeSettings(caulkBorders: true, caulkBorderRadius: 1),
      const ExtraColors(
        codeHighlight: ThemeSolarizedColors.violet,
        linkColor: ThemeSolarizedColors.cyan,
      ),
    ]);
  }
}
