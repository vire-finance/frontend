import '../../shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.blue400,
      onPrimary: AppColors.basicWhite,
      primaryContainer: AppColors.blue50, 
      onPrimaryContainer: AppColors.blue700,

      secondary: AppColors.blue500,
      onSecondary: AppColors.basicWhite,

      tertiary: AppColors.orange400,
      onTertiary: AppColors.basicWhite,

      error: AppColors.red600,
      onError: AppColors.basicWhite,
      errorContainer: AppColors.red50,
      onErrorContainer: AppColors.red600,

      surface: AppColors.white, 
      onSurface: AppColors.grey800,
      onSurfaceVariant: AppColors.grey400, 
      outline: AppColors.grey100, 
      outlineVariant: AppColors.blue100,
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
      bodyColor: AppColors.grey800,
      displayColor: AppColors.grey800,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.basicWhite,
      textTheme: textTheme,
      dividerColor: AppColors.grey100,
      inputDecorationTheme: const InputDecorationTheme(
        filled: true, fillColor: AppColors.inputFill,
        hintStyle: AppInputStyles.hint, labelStyle: AppInputStyles.label,
        contentPadding: AppInputStyles.padding, isDense: true,
        border: AppInputStyles.border, enabledBorder: AppInputStyles.border,
        focusedBorder: AppInputStyles.border, disabledBorder: AppInputStyles.border,
        errorBorder: AppInputStyles.errorBorder, focusedErrorBorder: AppInputStyles.errorBorder,
      ),
    );
  }
}