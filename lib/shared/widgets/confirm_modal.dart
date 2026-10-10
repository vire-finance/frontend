import 'package:flutter/material.dart';

class ConfirmModal {
  static Future<void> showCreated(
      BuildContext context, {
        required bool isCard,
      }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                "assets/images/Regular Images/Mascot - You're Good.png",
                height: 112,
              ),
              const SizedBox(height: 10),
              Text(
                isCard ? 'Card Successfully Created!' : 'Pocket Successfully Created!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF3260CD),
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isCard
                    ? 'The virtual card has been successfully generated.'
                    : 'Pocket has been successfully generated.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Back'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}