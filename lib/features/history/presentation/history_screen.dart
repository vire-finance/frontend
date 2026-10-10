import '../../../shared/widgets/app_search_bar.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bottom_nav_shell.dart';
import '../../dashboard/presentation/employee_dashboard_screen.dart';
import '../../dashboard/presentation/owner_dashboard_screen.dart';
import '../../document/presentation/employee/employee_document_list_screen.dart';
import '../../document/presentation/owner/owner_document_list_screen.dart';
import '../../pocket/presentation/employee/employee_pocket_list_screen.dart';
import '../../pocket/presentation/owner/owner_pocket_list_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../data/transaction_model.dart';
import '../data/transaction_repository.dart';
import 'transaction_detail_screen.dart';
import 'widgets/transaction_tile.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({this.employee = false, this.cardId, super.key});
  final bool employee;
  final String? cardId;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _category;
  bool _newestFirst = true;
  final _repository = TransactionRepository.instance;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _repository.load(cardId: widget.cardId).catchError((error) {
      if (mounted) setState(() => _loadError = apiErrorMessage(error));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.basicWhite,
        appBar: AppBar(
            title: const Text('Transactions History',
                style: TextStyle(
                    color: AppColors.blue900,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            centerTitle: true,
            backgroundColor: AppColors.basicWhite,
            elevation: 0),
        bottomNavigationBar: AppNavbar(
            items:
                widget.employee ? employeeNavigationItems : vireNavigationItems,
            selectedIndex: 3,
            onDestinationSelected: _selectDestination),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AnimatedBuilder(
                animation: _repository,
                builder: (context, _) {
                  final all = _repository.transactions;
                  final categories = all
                      .map((item) => item.category)
                      .whereType<String>()
                      .where((item) => item.isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();
                  final transactions = all.where((item) {
                    final matchesSearch =
                        '${item.title} ${item.category ?? ''} ${item.sourceAccount}'
                            .toLowerCase()
                            .contains(_query.toLowerCase());
                    return matchesSearch &&
                        (_category == null || item.category == _category);
                  }).toList()
                    ..sort((a, b) => _newestFirst
                        ? b.dateTime.compareTo(a.dateTime)
                        : a.dateTime.compareTo(b.dateTime));
                  return Column(children: [
                    const Divider(height: 1, color: AppColors.grey50),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                        child: Row(children: [
                          Expanded(
                            child: SizedBox(
                              height: 42,
                              child: AppSearchBar(
                                  controller: _searchController,
                                  onChanged: (value) =>
                                      setState(() => _query = value),
                                  hint: 'Search Transaction...'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          PopupMenuButton<String?>(
                              onSelected: (value) =>
                                  setState(() => _category = value),
                              itemBuilder: (context) => [
                                    const PopupMenuItem<String?>(
                                        value: null,
                                        child: Text('All categories')),
                                    for (final category in categories)
                                      PopupMenuItem<String?>(
                                          value: category,
                                          child: Text(category))
                                  ],
                              child:
                                  const _ToolbarButton(icon: Icons.filter_alt)),
                          const SizedBox(width: 6),
                          _ToolbarButton(
                              icon: Icons.swap_vert,
                              onTap: () =>
                                  setState(() => _newestFirst = !_newestFirst)),
                        ])),
                    SizedBox(
                        height: 48,
                        child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            children: [
                              _CategoryChip(
                                  label: 'All Transactions',
                                  selected: _category == null,
                                  onTap: () =>
                                      setState(() => _category = null)),
                              for (final category in categories) ...[
                                const SizedBox(width: 8),
                                _CategoryChip(
                                    label: category,
                                    selected: _category == category,
                                    onTap: () =>
                                        setState(() => _category = category)),
                              ],
                            ])),
                    Expanded(
                        child: transactions.isEmpty
                            ? _repository.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : _loadError != null
                                    ? Center(
                                        child: Padding(
                                            padding: const EdgeInsets.all(24),
                                            child: Text(_loadError!,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                    color: AppColors.red700))))
                                    : _EmptyHistory(
                                        hasQuery: _query.isNotEmpty ||
                                            _category != null)
                            : ListView(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 10, 20, 20),
                                children: [
                                    for (final group
                                        in _groupTransactions(transactions)
                                            .entries) ...[
                                      Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 10, top: 4),
                                          child: Text(group.key,
                                              style: const TextStyle(
                                                  color: AppColors.blue500,
                                                  fontWeight:
                                                      FontWeight.w700))),
                                      for (final transaction in group.value)
                                        TransactionTile(
                                            transaction: transaction,
                                            onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute<void>(
                                                    builder: (_) =>
                                                        TransactionDetailScreen(
                                                            transaction:
                                                                transaction)))),
                                    ],
                                  ])),
                  ]);
                },
              ),
            ),
          ),
        ),
      );

  Map<String, List<TransactionData>> _groupTransactions(
      List<TransactionData> transactions) {
    final today = DateTime.now();
    final startToday = DateTime(today.year, today.month, today.day);
    final startWeek = startToday.subtract(Duration(days: today.weekday - 1));
    final groups = <String, List<TransactionData>>{};
    for (final item in transactions) {
      final date = item.dateTime;
      final title = !date.isBefore(startToday)
          ? 'Today'
          : !date.isBefore(startWeek)
              ? 'This Week'
              : 'Earlier';
      groups.putIfAbsent(title, () => []).add(item);
    }
    return groups;
  }

  void _selectDestination(int index) {
    if (index == 3) return;
    final Widget? screen = widget.employee
        ? switch (index) {
            0 => const EmployeeDashboardScreen(),
            1 => const EmployeePocketListScreen(),
            2 => const EmployeeDocumentListScreen(),
            4 => const EmployeeProfileScreen(),
            _ => null,
          }
        : switch (index) {
            0 => const OwnerDashboardScreen(),
            1 => const OwnerPocketListScreen(),
            2 => const OwnerDocumentListScreen(),
            4 => const OwnerProfileScreen(),
            _ => null,
          };
    if (screen != null)
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => screen), (route) => false);
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.blue400,
      labelStyle: TextStyle(
          color: selected ? AppColors.white : AppColors.blue500,
          fontWeight: FontWeight.w600),
      side: const BorderSide(color: AppColors.blue500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)));
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 42,
      height: 42,
      child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: AppColors.blue500),
          style: IconButton.styleFrom(
              side: const BorderSide(color: AppColors.grey100),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13)))));
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.hasQuery});
  final bool hasQuery;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.receipt_long_outlined,
                size: 54, color: AppColors.blue200),
            const SizedBox(height: 12),
            Text(hasQuery ? 'No matching transactions' : 'No transactions yet',
                style: const TextStyle(
                    color: AppColors.blue800,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
                hasQuery
                    ? 'Try another search or category.'
                    : 'Transaction history will appear here when available.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.grey500, height: 1.4))
          ])));
}
