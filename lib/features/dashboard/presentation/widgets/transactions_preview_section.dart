import '../../../../shared/widgets/app_search_bar.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/dashboard_model.dart';
import 'summary_card.dart';

class TransactionsPreviewSection extends StatefulWidget {
  const TransactionsPreviewSection({
    required this.transactions,
    this.transactionCount,
    this.onViewAll,
    this.onExport,
    super.key,
  });

  final List<DashboardTransaction> transactions;
  final int? transactionCount;
  final VoidCallback? onViewAll;
  final VoidCallback? onExport;

  @override
  State<TransactionsPreviewSection> createState() =>
      _TransactionsPreviewSectionState();
}

class _TransactionsPreviewSectionState
    extends State<TransactionsPreviewSection> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.transactions
        .where((item) => '${item.merchant} ${item.category}'
            .toLowerCase()
            .contains(_query.toLowerCase()))
        .take(3)
        .toList();

    return SummaryCard(
      icon: Icons.receipt_long_outlined,
      title: 'Transactions (${widget.transactionCount?.toString() ?? '—'})',
      trailing: OutlinedButton.icon(
        onPressed: widget.onExport,
        icon: const Icon(Icons.download_outlined, size: 14),
        label: const Text('Export', style: TextStyle(fontSize: 11)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blue500,
          side: const BorderSide(color: AppColors.blue500),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: AppSearchBar(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      hint: 'Search Transaction...'),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.filter_alt, color: AppColors.blue500),
                style: IconButton.styleFrom(
                  side: const BorderSide(color: AppColors.grey100),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.swap_vert, color: AppColors.blue500),
                style: IconButton.styleFrom(
                  side: const BorderSide(color: AppColors.grey100),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'Transactions will appear here when available.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey500),
              ),
            ),
          for (final transaction in visible)
            _TransactionRow(transaction: transaction),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: null,
                icon: const Icon(Icons.chevron_left),
              ),
              Container(
                width: 38,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.blue500,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Text(
                  '1',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onViewAll,
                icon: const Icon(
                  Icons.chevron_right,
                  color: AppColors.blue500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final DashboardTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final merchant = transaction.merchant.trim();
    final initials =
        merchant.isEmpty ? '?' : merchant.substring(0, 1).toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9477FF), Color(0xFFB2A1FF)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.merchant,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(transaction.date,
                    style: const TextStyle(
                        color: AppColors.grey400, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.blue50,
                  border: Border.all(color: AppColors.blue400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  transaction.category,
                  style: const TextStyle(color: AppColors.blue700, fontSize: 9),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '− ${formatDashboardAmount(transaction.amount, currency: transaction.currency)}',
                style: const TextStyle(
                  color: AppColors.red500,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
