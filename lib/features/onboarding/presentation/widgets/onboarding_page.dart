import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class OnboardingSlide {
  const OnboardingSlide({
    required this.imagePath,
    required this.title,
    required this.description,
  });

  final String imagePath;
  final String title;
  final String description;
}

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    required this.slide,
    required this.pageIndex,
    required this.pageCount,
    required this.onSkip,
    required this.onContinue,
    required this.onBack,
    super.key,
  });

  final OnboardingSlide slide;
  final int pageIndex;
  final int pageCount;
  final VoidCallback onSkip;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final expandedArtwork = pageIndex < 2;
          final imageFlex = expandedArtwork
              ? (constraints.maxHeight < 760 ? 63 : 67)
              : (constraints.maxHeight < 760 ? 55 : 61);
          final contentFlex = 100 - imageFlex;

          return Column(
            children: [
              Expanded(
                flex: imageFlex,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: expandedArtwork ? 8 : 28,
                          bottom: expandedArtwork ? 28 : 34,
                        ),
                        child: Image.asset(
                          slide.imagePath,
                          fit: expandedArtwork ? BoxFit.cover : BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 20,
                      right: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (pageIndex > 0)
                            TextButton.icon(
                              onPressed: onBack,
                              icon: const Icon(
                                Icons.chevron_left,
                                color: AppColors.grey500,
                              ),
                              label: Text(
                                'Back',
                                style: AppTextStyles.l3.copyWith(
                                  color: AppColors.grey700,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(64, 36),
                                alignment: Alignment.centerLeft,
                              ),
                            )
                          else
                            const SizedBox(width: 64, height: 36),
                          SizedBox(
                            width: 96,
                            height: 36,
                            child: TextButton(
                              onPressed: onSkip,
                              style: TextButton.styleFrom(
                                backgroundColor: AppColors.orange100,
                                foregroundColor: AppColors.orange700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                'Skip',
                                style: AppTextStyles.l3.medium.copyWith(
                                  color: AppColors.orange700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 14,
                      child: _PageIndicator(
                        currentPage: pageIndex,
                        pageCount: pageCount,
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: AppColors.grey50),
              Expanded(
                flex: contentFlex,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        slide.title,
                        style: AppTextStyles.h3.semiBold.copyWith(
                          color: AppColors.blue400,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            slide.description,
                            textAlign: TextAlign.justify,
                            style: AppTextStyles.p2.copyWith(
                              color: AppColors.grey800,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: 204,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: onContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.blue400,
                              foregroundColor: AppColors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Continue',
                              style: AppTextStyles.l2.semiBold.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.currentPage,
    required this.pageCount,
  });

  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isActive ? 52 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? AppColors.orange400 : AppColors.orange100,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
