import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../data/transaction_model.dart';
import '../../document/presentation/purchase_requests_screen.dart';
import '../../../core/network/api_client.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({required this.transaction, super.key});
  final TransactionData transaction;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.basicWhite,
        appBar: AppBar(
            title: const Text('Transaction Details',
                style: TextStyle(
                    color: AppColors.blue900,
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            centerTitle: true,
            backgroundColor: AppColors.basicWhite,
            foregroundColor: AppColors.blue900,
            elevation: 0),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                children: [
                  Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(transaction.title,
                              style: const TextStyle(
                                  color: AppColors.grey700,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 5),
                          Text(transaction.location ?? '—',
                              style: const TextStyle(color: AppColors.grey500))
                        ])),
                    CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.blue400,
                        child: Text(_initials(transaction.title),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700))),
                  ]),
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: AppColors.grey100, height: 1)),
                  Text('- ${formatTransactionAmount(transaction.amount)}',
                      style: const TextStyle(
                          color: AppColors.orange500,
                          fontSize: 25,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 24),
                  _Info(
                      label: 'Transaction ID',
                      value: transaction.transactionId ?? '—',
                      trailing:
                          _TransactionStatusBadge(status: transaction.status)),
                  _Info(
                      label: 'Source of Fund',
                      value: transaction.sourceAccount),
                  _Info(
                      label: 'Date and Time',
                      value: formatTransactionDate(transaction.dateTime)),
                  _Info(
                      label: 'Acquirer Name',
                      value: transaction.acquirer ?? '—'),
                  _Info(
                      label: 'Fee',
                      value: transaction.fee == null
                          ? '—'
                          : formatTransactionAmount(transaction.fee!)),
                  _Info(
                      label: 'Payment Method',
                      value: transaction.paymentMethod),
                  if (transaction.category?.isNotEmpty == true)
                    _Info(label: 'Category', value: transaction.category!),
                  if (transaction.requestId != null &&
                      transaction.status == 'APPROVED')
                    FilledButton.icon(
                        onPressed: () async {
                          final owner =
                              await ApiClient.instance.role == 'OWNER';
                          if (context.mounted)
                            Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                    builder: (_) => PurchaseRequestDetailScreen(
                                        id: transaction.requestId!,
                                        owner: owner,
                                        receiptOnly: true)));
                        },
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Purchase Documents')),
                  const SizedBox(height: 18),
                  SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                          onPressed: () => Share.share(
                              '${transaction.title}\n${formatTransactionAmount(transaction.amount)}\n${transaction.transactionId ?? ''}\n${formatTransactionDate(transaction.dateTime)}'),
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('Share'))),
                ],
              ),
            ),
          ),
        ),
      );

  static String _initials(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '—';
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value, this.trailing});
  final String label;
  final String value;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(color: AppColors.grey400, fontSize: 14)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: AppColors.grey700,
                      fontSize: 16,
                      fontWeight: FontWeight.w600))),
          if (trailing != null) trailing!
        ])
      ]));
}

class _TransactionStatusBadge extends StatelessWidget {
  const _TransactionStatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = switch (status.toUpperCase()) {
      'APPROVED' => ('Success', AppColors.green700, AppColors.green50),
      'PENDING' => ('Pending', AppColors.orange700, AppColors.orange50),
      'DECLINED' => ('Declined', AppColors.red700, AppColors.red50),
      'FAILED' => ('Failed', AppColors.red700, AppColors.red50),
      _ => (status, AppColors.grey700, AppColors.grey50),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}
