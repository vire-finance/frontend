import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'core/theme/app_theme.dart';

class VireApp extends StatelessWidget {
  const VireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vire',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _ThemePreviewScreen(),
    );
  }
}

class _ThemePreviewScreen extends StatelessWidget {
  const _ThemePreviewScreen();

  @override
  Widget build(BuildContext context) {
    const swatches = <Color>[
      AppColors.blue500,
      AppColors.orange500,
      AppColors.green500,
      AppColors.red500,
      AppColors.grey500,
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vire', style: AppTextStyles.d2.bold),
              const SizedBox(height: 8),
              Text('Inter Tight - Light', style: AppTextStyles.p1.light),
              Text('Inter Tight - Regular', style: AppTextStyles.p1),
              Text('Inter Tight - Medium', style: AppTextStyles.p1.medium),
              Text('Inter Tight - SemiBold', style: AppTextStyles.p1.semiBold),
              Text('Inter Tight - Bold', style: AppTextStyles.p1.bold),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final color in swatches)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}