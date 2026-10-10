import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_search_bar.dart';
import 'purchase_requests_screen.dart';

class RequestDocumentList extends StatefulWidget {
  const RequestDocumentList({required this.owner, super.key});
  final bool owner;
  @override
  State<RequestDocumentList> createState() => _RequestDocumentListState();
}

class _RequestDocumentListState extends State<RequestDocumentList>
    with WidgetsBindingObserver {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  String? _filter, _error;
  DateTimeRange? _range;
  bool _loading = true, _fetching = false, _newestFirst = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted &&
          ModalRoute.of(context)?.isCurrent == true &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _load();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
          '/fund-requests',
          queryParameters: {'limit': 200});
      if (mounted) {
        setState(() {
          _rows = (response.data?['items'] as List? ?? [])
              .map((r) => Map<String, dynamic>.from(r as Map))
              .toList();
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = apiErrorMessage(error));
    } finally {
      _fetching = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  String _status(Map<String, dynamic> row) => switch (row['status']) {
        'REJECTED' => 'Rejected',
        'APPROVED' || 'COMPLETED' => 'Accepted',
        _ => 'Waiting',
      };

  DateTime _date(Map<String, dynamic> row) =>
      DateTime.tryParse('${row['created_at'] ?? row['needed_by']}')
          ?.toLocal() ??
      DateTime.fromMillisecondsSinceEpoch(0);

  String _group(DateTime date) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(date, now)) return 'Today';
    if (DateUtils.isSameDay(date, now.subtract(const Duration(days: 1))))
      return 'Yesterday';
    if (date.year == now.year && date.month == now.month) return 'This Month';
    final previous = DateTime(now.year, now.month - 1);
    if (date.year == previous.year && date.month == previous.month)
      return 'Last Month';
    return '${const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ][date.month - 1]} ${date.year}';
  }

  Color _color(String status) => switch (status) {
        'Rejected' => const Color(0xFFFF343D),
        'Accepted' => const Color(0xFF60CC68),
        _ => const Color(0xFFFF982B),
      };

  Future<void> _open(Map<String, dynamic> row) async {
    await Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => PurchaseRequestDetailScreen(
                id: '${row['id']}',
                owner: widget.owner,
                receiptOnly: row['paid_at'] != null)));
    await _load();
  }

  Future<void> _filters() async {
    await showModalBottomSheet<void>(
        context: context,
        builder: (sheet) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final value in ['All', 'Waiting', 'Rejected', 'Accepted'])
                ListTile(
                    title: Text(value),
                    trailing: (_filter ?? 'All') == value
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () {
                      setState(() => _filter = value == 'All' ? null : value);
                      Navigator.pop(sheet);
                    }),
              ListTile(
                  title: const Text('Choose date range'),
                  leading: const Icon(Icons.date_range),
                  onTap: () async {
                    Navigator.pop(sheet);
                    final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        initialDateRange: _range);
                    if (mounted && range != null)
                      setState(() => _range = range);
                  }),
              if (_range != null)
                ListTile(
                    title: const Text('Clear date range'),
                    onTap: () {
                      setState(() => _range = null);
                      Navigator.pop(sheet);
                    }),
            ])));
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows.where((row) {
      final date = _date(row);
      return (_filter == null || _status(row) == _filter) &&
          (_range == null ||
              (!date.isBefore(_range!.start) &&
                  date.isBefore(_range!.end.add(const Duration(days: 1))))) &&
          '${row['display_id']} ${row['party_name']} ${row['explanation']} ${row['category']}'
              .toLowerCase()
              .contains(_search.text.toLowerCase());
    }).toList()
      ..sort((a, b) => _newestFirst
          ? _date(b).compareTo(_date(a))
          : _date(a).compareTo(_date(b)));
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      groups.putIfAbsent(_group(_date(row)), () => []).add(row);
    }
    return Scaffold(
        backgroundColor: AppColors.basicWhite,
        body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    children: [
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Image.asset(
                              'assets/images/Regular Images/Logo - V.png',
                              width: 32,
                              height: 32)),
                      const SizedBox(height: 18),
                      Row(children: [
                        Expanded(
                            child: Text(
                                widget.owner
                                    ? 'Your Documents'
                                    : 'Your Requests',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.blue900))),
                        if (!widget.owner)
                          OutlinedButton.icon(
                              onPressed: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const PurchaseRequestFormScreen()));
                                await _load();
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Document')),
                      ]),
                      const SizedBox(height: 16),
                      Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppColors.grey100),
                              borderRadius: BorderRadius.circular(20)),
                          child: IntrinsicHeight(
                              child: Row(children: [
                            for (final status in [
                              'Waiting',
                              'Rejected',
                              'Accepted'
                            ]) ...[
                              if (status != 'Waiting')
                                const VerticalDivider(
                                    width: 1, color: AppColors.blue100),
                              Expanded(
                                  child: InkWell(
                                      onTap: () => setState(() => _filter =
                                          _filter == status ? null : status),
                                      child: Column(children: [
                                        Text(status,
                                            style: TextStyle(
                                                color: AppColors.blue900,
                                                fontWeight: _filter == status
                                                    ? FontWeight.bold
                                                    : FontWeight.w500)),
                                        const SizedBox(height: 10),
                                        Text(
                                            '${_rows.where((row) => _status(row) == status).length}',
                                            style: TextStyle(
                                                fontSize: 27,
                                                color: _color(status),
                                                fontWeight: FontWeight.w600)),
                                      ]))),
                            ],
                          ]))),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                            child: AppSearchBar(
                                controller: _search,
                                hint: 'Search Transaction...',
                                onChanged: (_) => setState(() {}))),
                        const SizedBox(width: 8),
                        _control(
                            Icons.filter_alt, 'Filter documents', _filters),
                        const SizedBox(width: 8),
                        _control(Icons.swap_vert, 'Sort documents',
                            () => setState(() => _newestFirst = !_newestFirst)),
                      ]),
                      if (_loading)
                        const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator())),
                      if (_error != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Text(_error!,
                                style:
                                    const TextStyle(color: AppColors.red500))),
                      if (!_loading && rows.isEmpty)
                        const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No documents found.')),
                      for (final group in groups.entries) ...[
                        Padding(
                            padding: const EdgeInsets.only(top: 24, bottom: 12),
                            child: Text(group.key,
                                style: const TextStyle(
                                    color: AppColors.blue600,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700))),
                        for (final row in group.value) _tile(row),
                      ],
                    ]))));
  }

  Widget _control(IconData icon, String tooltip, VoidCallback action) =>
      Container(
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.grey100),
              borderRadius: BorderRadius.circular(12)),
          child: IconButton(
              tooltip: tooltip,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
              padding: const EdgeInsets.all(6),
              onPressed: action,
              icon: Icon(icon, color: AppColors.blue500, size: 22)));

  Widget _tile(Map<String, dynamic> row) {
    final status = _status(row), date = _date(row);
    final dateText =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final amount = num.tryParse('${row['total_amount']}')?.round() ?? 0;
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.grey100)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
                onTap: () => _open(row),
                child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 12),
                    child: Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('${row['display_id'] ?? row['party_name']}',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            Text(
                                '$dateText | ${row['explanation']} | ${row['category']}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.grey700)),
                            if (row['receipt_status'] == 'AWAITING_RECEIPT' ||
                                row['workflow_status'] == 'RECEIPT_OVERDUE')
                              Text(
                                  row['workflow_status'] == 'RECEIPT_OVERDUE'
                                      ? 'Receipt overdue'
                                      : 'Receipt required',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.orange500)),
                          ])),
                      const SizedBox(width: 12),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                    color: _color(status),
                                    borderRadius: BorderRadius.circular(7)),
                                child: Text(status,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600))),
                            const SizedBox(height: 10),
                            Text(formatIdrInput(amount),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: AppColors.grey700)),
                          ]),
                    ])))));
  }
}
