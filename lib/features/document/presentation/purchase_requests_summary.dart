import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import 'owner/owner_document_list_screen.dart';

class PurchaseRequestsSummary extends StatefulWidget {
  const PurchaseRequestsSummary({this.onChanged, super.key});
  final Future<void> Function()? onChanged;
  @override
  State<PurchaseRequestsSummary> createState() =>
      _PurchaseRequestsSummaryState();
}

class _PurchaseRequestsSummaryState extends State<PurchaseRequestsSummary> {
  int _pending = 0, _overdue = 0;
  Timer? _timer;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (ModalRoute.of(context)?.isCurrent == true) _load();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (_busy) return;
    _busy = true;
    try {
      final res = await ApiClient.instance.dio.get<Map<String, dynamic>>(
          '/fund-requests',
          queryParameters: {'limit': 200});
      final rows = res.data?['items'] as List? ?? [];
      if (mounted)
        setState(() {
          _pending =
              rows.where((r) => r['status'] == 'PENDING_APPROVAL').length;
          _overdue = rows
              .where((r) => r['workflow_status'] == 'RECEIPT_OVERDUE')
              .length;
        });
    } catch (_) {
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) => Card(
      child: ListTile(
          leading:
              const Icon(Icons.assignment_outlined, color: AppColors.blue500),
          title: const Text('Purchase Requests',
              style: TextStyle(
                  color: AppColors.blue500, fontWeight: FontWeight.bold)),
          subtitle: Text(
              '$_pending pending approval · $_overdue receipts overdue',
              style: TextStyle(
                  color: _overdue > 0 ? AppColors.red500 : AppColors.grey600)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => const OwnerDocumentListScreen()));
            await _load();
            await widget.onChanged?.call();
          }));
}
