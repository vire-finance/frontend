import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.blue500,
      onPrimary: AppColors.white,
      secondary: AppColors.orange500,
      onSecondary: AppColors.grey900, 
      error: AppColors.red600,
      onError: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.grey900,
      outline: AppColors.grey100,
    );

    final textTheme = TextTheme(
      displayLarge: AppTextStyles.d1,
      displayMedium: AppTextStyles.d2,
      displaySmall: AppTextStyles.d3,
      headlineLarge: AppTextStyles.h1,
      headlineMedium: AppTextStyles.h2,
      headlineSmall: AppTextStyles.h3,
      titleLarge: AppTextStyles.h4,
      titleMedium: AppTextStyles.h5,
      titleSmall: AppTextStyles.h6,
      bodyLarge: AppTextStyles.p1,
      bodyMedium: AppTextStyles.p2,
      bodySmall: AppTextStyles.p3,
      labelLarge: AppTextStyles.l2,
      labelMedium: AppTextStyles.l4,
      labelSmall: AppTextStyles.l5,
    ).apply(
      bodyColor: AppColors.grey900,
      displayColor: AppColors.grey900,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.white,
      textTheme: textTheme,
      dividerColor: AppColors.grey100,
    );
  }
}