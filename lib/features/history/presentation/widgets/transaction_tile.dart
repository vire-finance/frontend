import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile(
      {required this.transaction, required this.onTap, super.key});
  final TransactionData transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _merchantColor(transaction.title);
    final title = transaction.title.trim();
    final initials = title.isEmpty ? '?' : title.substring(0, 1).toUpperCase();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(10)),
              child: Center(
                  child: Text(initials,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 22)))),
          const SizedBox(width: 9),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(transaction.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.grey800, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(formatTransactionDate(transaction.dateTime),
                    style: const TextStyle(
                        color: AppColors.grey400, fontSize: 11)),
              ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (transaction.category?.isNotEmpty == true)
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      border: Border.all(color: AppColors.blue500),
                      borderRadius: BorderRadius.circular(5)),
                  child: Text(transaction.category!,
                      style: const TextStyle(
                          color: AppColors.blue600, fontSize: 10))),
            const SizedBox(height: 5),
            Text('- ${formatTransactionAmount(transaction.amount)}',
                style: const TextStyle(
                    color: AppColors.red500,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ]),
        ]),
      ),
    );
  }

  static Color _merchantColor(String title) {
    const palette = [
      AppColors.blue500,
      AppColors.orange500,
      AppColors.green600,
      AppColors.red500,
      AppColors.blue700
    ];
    return palette[title.hashCode.abs() % palette.length];
  }
}
