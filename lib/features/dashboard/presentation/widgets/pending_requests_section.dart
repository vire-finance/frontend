import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../data/dashboard_model.dart';
import 'payment_request_tile.dart';
import 'summary_card.dart';

class PendingRequestsSection extends StatefulWidget {
  const PendingRequestsSection(
      {required this.requests,
      this.requestCount,
      this.onRequestTap,
      this.onViewAll,
      super.key});
  final List<PaymentRequest> requests;
  final int? requestCount;
  final ValueChanged<PaymentRequest>? onRequestTap;
  final VoidCallback? onViewAll;
  @override
  State<PendingRequestsSection> createState() => _PendingRequestsSectionState();
}

class _PendingRequestsSectionState extends State<PendingRequestsSection> {
  final _search = TextEditingController();
  String _query = '';
  String? _category;
  int _page = 0;
  bool _newestFirst = true;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _filter() async {
    final categories = widget.requests
        .map((r) => r.category)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    await showModalBottomSheet<void>(
        context: context,
        builder: (sheet) => SafeArea(
              child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Expense Category',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue900))),
                for (final category in <String?>[null, ...categories])
                  ListTile(
                      title: Text(category ?? 'All Categories'),
                      trailing: _category == category
                          ? const Icon(Icons.check, color: AppColors.blue500)
                          : null,
                      onTap: () {
                        setState(() {
                          _category = category;
                          _page = 0;
                        });
                        Navigator.pop(sheet);
                      }),
              ])),
            ));
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.requests
        .where((r) =>
            '${r.reference} ${r.description} ${r.category ?? ''}'
                .toLowerCase()
                .contains(_query.toLowerCase()) &&
            (_category == null || r.category == _category))
        .toList()
      ..sort((a, b) => _newestFirst
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt));
    final pages = math.max(1, (visible.length / 2).ceil());
    final page = math.min(_page, pages - 1);
    return SummaryCard(
        icon: Icons.pending_actions_outlined,
        title:
            'Pending Payment Requests (${widget.requestCount ?? widget.requests.length})',
        trailing: widget.onViewAll == null
            ? null
            : IconButton(
                tooltip: 'View all requests',
                icon: const Icon(Icons.open_in_new, size: 18),
                onPressed: widget.onViewAll),
        child: Column(children: [
          Row(children: [
            Expanded(
                child: AppSearchBar(
                    controller: _search,
                    hint: 'Search Transaction...',
                    onChanged: (value) => setState(() {
                          _query = value;
                          _page = 0;
                        }))),
            const SizedBox(width: 6),
            _tool(Icons.filter_alt, 'Filter requests', _filter,
                active: _category != null),
            const SizedBox(width: 6),
            _tool(
                Icons.swap_vert,
                'Sort requests',
                () => setState(() {
                      _newestFirst = !_newestFirst;
                      _page = 0;
                    })),
          ]),
          const SizedBox(height: 14),
          if (visible.isEmpty)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No pending payment requests.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.grey500))),
          for (final request in visible.skip(page * 2).take(2))
            Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: PaymentRequestTile(
                    request: request,
                    onTap: widget.onRequestTap == null
                        ? null
                        : () => widget.onRequestTap!(request))),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
                tooltip: 'Previous page',
                onPressed:
                    page == 0 ? null : () => setState(() => _page = page - 1),
                icon: const Icon(Icons.chevron_left),
                color: AppColors.blue500,
                disabledColor: AppColors.blue200),
            const SizedBox(width: 12),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.blue600,
                    borderRadius: BorderRadius.circular(6)),
                child: Text('${page + 1}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700))),
            const SizedBox(width: 12),
            IconButton(
                tooltip: 'Next page',
                onPressed: page + 1 >= pages
                    ? null
                    : () => setState(() => _page = page + 1),
                icon: const Icon(Icons.chevron_right),
                color: AppColors.blue500,
                disabledColor: AppColors.blue200),
          ]),
        ]));
  }

  Widget _tool(IconData icon, String label, VoidCallback action,
          {bool active = false}) =>
      SizedBox(
          width: 40,
          height: 42,
          child: IconButton(
              tooltip: label,
              onPressed: action,
              icon: Icon(icon, color: AppColors.blue500),
              style: IconButton.styleFrom(
                  backgroundColor: active ? AppColors.blue50 : null,
                  side: const BorderSide(color: AppColors.grey100),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)))));
}
