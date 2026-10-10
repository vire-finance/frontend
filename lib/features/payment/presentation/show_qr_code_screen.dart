import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money_formatter.dart';
import '../data/payment_model.dart';

class ShowQrCodeScreen extends StatelessWidget {
  const ShowQrCodeScreen({required this.code, this.payment, super.key});
  final String code;
  final PaymentDraft? payment;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.basicWhite,
        appBar: AppBar(
            title: const Text('Payment'),
            centerTitle: true,
            backgroundColor: AppColors.basicWhite,
            foregroundColor: AppColors.blue900,
            elevation: 0),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                          color: AppColors.white,
                          border: Border.all(color: AppColors.grey50),
                          borderRadius: BorderRadius.circular(20)),
                      child: QrImageView(
                          data: code,
                          version: QrVersions.auto,
                          size: (MediaQuery.sizeOf(context).width - 112)
                              .clamp(160, 300)
                              .toDouble(),
                          eyeStyle: const QrEyeStyle(color: AppColors.blue500),
                          dataModuleStyle: const QrDataModuleStyle(
                              color: AppColors.blue500)),
                    ),
                    if (payment != null) ...[
                      const SizedBox(height: 24),
                      Text(payment!.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.blue900)),
                      const SizedBox(height: 8),
                      Text(formatIdrInput(payment!.amount),
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.orange500)),
                      const SizedBox(height: 8),
                      Text('${payment!.sourceCard.name} • ${payment!.category}',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      const Text(
                          'Simulation QR. Confirm to complete the payment.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: AppColors.grey500)),
                      const SizedBox(height: 24),
                      SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Confirm Payment'))),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
