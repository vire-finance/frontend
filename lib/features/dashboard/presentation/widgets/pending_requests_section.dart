import '../../../../shared/widgets/app_search_bar.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/dashboard_model.dart';
import 'payment_request_tile.dart';
import 'summary_card.dart';

class PendingRequestsSection extends StatefulWidget {
  const PendingRequestsSection(
      {required this.requests, this.requestCount, super.key});
  final List<PaymentRequest> requests;
  final int? requestCount;

  @override
  State<PendingRequestsSection> createState() => _PendingRequestsSectionState();
}

class _PendingRequestsSectionState extends State<PendingRequestsSection> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.requests
        .where((item) => '${item.reference} ${item.description}'
            .toLowerCase()
            .contains(_query.toLowerCase()))
        .toList();
    return SummaryCard(
      icon: Icons.pending_actions_outlined,
      title:
          'Pending Payment Requests (${widget.requestCount?.toString() ?? '—'})',
      child: Column(children: [
        _SearchTools(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value)),
        const SizedBox(height: 14),
        if (visible.isEmpty)
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Pending requests will appear here when available.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grey500))),
        for (final request in visible)
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PaymentRequestTile(request: request)),
        const SizedBox(height: 4),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.chevron_left, color: AppColors.blue200, size: 32),
          SizedBox(width: 18),
          Text('—', style: TextStyle(color: AppColors.blue500)),
          SizedBox(width: 18),
          Icon(Icons.chevron_right, color: AppColors.blue200, size: 32)
        ]),
      ]),
    );
  }
}

class _SearchTools extends StatelessWidget {
  const _SearchTools({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 42,
              child: AppSearchBar(
                  controller: controller,
                  onChanged: onChanged,
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
      );
}
