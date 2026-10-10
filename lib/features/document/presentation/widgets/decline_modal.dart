import '../../../../shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class DocumentActionModal {
  static Future<String?> showDecline(BuildContext context) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MascotClose(onClose: () => Navigator.pop(dialogContext)),
                const SizedBox(height: 8),
                const Text(
                  'Reject This Request?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.blue500,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This request will be marked as declined and the requester will be notified.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grey700, height: 1.4),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Reason for Decline  *',
                    style: TextStyle(color: AppColors.blue500),
                  ),
                ),
                const SizedBox(height: 8),
                AppFormField(controller: controller, maxLines: 2, decoration: AppInputDecoration(hintText: 'Type your reason here...'), validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please provide a reason.'
                      : null),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(dialogContext, controller.text.trim());
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.red500,
                        ),
                        child: const Text('Yes'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.orange100,
                          foregroundColor: AppColors.orange700,
                        ),
                        child: const Text('No'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  static Future<bool?> showConfirmPayment(BuildContext context) =>
      showDialog<bool>(
        context: context,
        builder: (dialogContext) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 12),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MascotClose(onClose: () => Navigator.pop(dialogContext)),
                const SizedBox(height: 8),
                const Text(
                  'Are You Sure?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.blue500,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Approving this will verify the document and queue it for manual invoice payment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grey700, height: 1.4),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.blue100,
                          foregroundColor: AppColors.blue600,
                        ),
                        child: const Text('Yes'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.blue400,
                        ),
                        child: const Text('No'),
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

class _MascotClose extends StatelessWidget {
  const _MascotClose({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 128,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              "assets/images/Regular Images/Mascot - Unsure.png",
              height: 112,
              fit: BoxFit.contain,
            ),
            Positioned(
              right: -12,
              top: -12,
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: AppColors.grey700),
              ),
            ),
          ],
        ),
      );
}
