import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/dashboard_model.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard(
      {required this.amount,
      required this.onDetails,
      required this.onPayment,
      required this.isHidden,
      required this.onToggleVisibility,
      super.key});
  final int? amount;
  final VoidCallback onDetails;
  final VoidCallback onPayment;
  final bool isHidden;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFE9F0FF), Color(0xFFEAF5FF)]),
            border: Border.all(color: AppColors.blue100),
            borderRadius: BorderRadius.circular(18)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: AppColors.blue500,
                    borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.remove, color: Colors.white)),
            const SizedBox(width: 14),
            const Text('Total Balance',
                style: TextStyle(
                    color: AppColors.blue800,
                    fontWeight: FontWeight.w700,
                    fontSize: 16))
          ]),
          Padding(
              padding: const EdgeInsets.fromLTRB(42, 9, 0, 12),
              child: Row(children: [
                Expanded(
                    child: Text(
                        isHidden ? '••••••••' : formatDashboardAmount(amount),
                        style: const TextStyle(
                            fontSize: 20,
                            color: AppColors.grey700,
                            fontWeight: FontWeight.w700))),
                IconButton(
                    onPressed: onToggleVisibility,
                    icon: Icon(
                        isHidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.blue500))
              ])),
          Row(children: [
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: onDetails,
                    icon: const Icon(Icons.article_outlined, size: 16),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.blue500,
                        side: const BorderSide(color: AppColors.blue500)))),
            const SizedBox(width: 8),
            Expanded(
                child: FilledButton.icon(
                    onPressed: onPayment,
                    icon: const Icon(Icons.qr_code, size: 16),
                    label: const Text('Payment'),
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.blue500)))
          ]),
        ]),
      );
}
