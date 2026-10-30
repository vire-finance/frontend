import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class AccountCreatedModal {
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onContinue,
  }) {
    return _showSuccessModal(
      context,
      title: 'Account Created!',
      description:
          "Your profile is ready. Let's complete a few quick setup steps "
          'to customize your workspace.',
      onContinue: onContinue,
    );
  }
}

class SetupCompleteModal {
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onContinue,
    String title = 'Setup complete!',
    String description =
        "Your workspace is all set. You're ready to explore your dashboard now.",
  }) {
    return _showSuccessModal(
      context,
      title: title,
      description: description,
      onContinue: onContinue,
    );
  }
}

Future<void> _showSuccessModal(
  BuildContext context, {
  required String title,
  required String description,
  required VoidCallback onContinue,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 112,
                      child: Image.asset(
                        "assets/images/Regular Images/Mascot - You're Good.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h3.bold.copyWith(
                        color: AppColors.blue500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.p2.copyWith(
                        color: AppColors.grey700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          onContinue();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue400,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Continue',
                          style: AppTextStyles.l3.semiBold.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.grey700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
