import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

part 'base_colors.dart';
part 'font_theme.dart';
part 'theme.dart';

abstract class VireTheme {
  ThemeData normalTheme();
  ThemeData darkTheme();
  ThemeData mapTheme(ThemeType type);
}