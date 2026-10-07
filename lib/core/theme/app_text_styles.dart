import 'package:flutter/painting.dart';

abstract final class AppTextStyles {
  static const String fontFamily = 'InterTight';

  static TextStyle _style(double size, double lineHeight) => TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        height: lineHeight / size,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        leadingDistribution: TextLeadingDistribution.even,
      );

  static final TextStyle d1 = _style(52, 70);
  static final TextStyle d2 = _style(44, 58);
  static final TextStyle d3 = _style(40, 52);

  static final TextStyle h1 = _style(36, 44);
  static final TextStyle h2 = _style(32, 40);
  static final TextStyle h3 = _style(28, 36);
  static final TextStyle h4 = _style(24, 32);
  static final TextStyle h5 = _style(20, 28);
  static final TextStyle h6 = _style(18, 24);

  static final TextStyle p1 = _style(18, 28);
  static final TextStyle p2 = _style(16, 22);
  static final TextStyle p3 = _style(12, 20);
  static final TextStyle p4 = _style(10, 15);
  static final TextStyle p5 = _style(8, 12);

  static final TextStyle l1 = _style(18, 24);
  static final TextStyle l2 = _style(16, 18);
  static final TextStyle l3 = _style(14, 16);
  static final TextStyle l4 = _style(12, 16);
  static final TextStyle l5 = _style(10, 14);
  static final TextStyle l6 = _style(8, 10);
}

extension AppFontWeight on TextStyle {
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);
  TextStyle get regular => copyWith(fontWeight: FontWeight.w400);
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);
}