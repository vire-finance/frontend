import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import 'owner/owner_document_list_screen.dart';
import '../../dashboard/data/dashboard_model.dart';
import '../../dashboard/presentation/widgets/pending_requests_section.dart';
import 'purchase_requests_screen.dart';

class PurchaseRequestsSummary extends StatefulWidget {
  const PurchaseRequestsSummary({this.onChanged, super.key});
  final Future<void> Function()? onChanged;
  @override
  State<PurchaseRequestsSummary> createState() =>
      _PurchaseRequestsSummaryState();
}

class _PurchaseRequestsSummaryState extends State<PurchaseRequestsSummary> {
  List<Map<String, dynamic>> _pending = [];
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
      if (mounted) {
        setState(() {
          _pending = rows
              .where((r) => r['status'] == 'PENDING_APPROVAL')
              .map((r) => Map<String, dynamic>.from(r as Map))
              .toList();
        });
      }
    } catch (_) {
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) => PendingRequestsSection(
      requestCount: _pending.length,
      requests: _pending
          .map((row) => PaymentRequest(
                id: '${row['id']}',
                reference:
                    '${row['reference'] ?? 'REQ-${row['id'].toString().split('').take(8).join().toUpperCase()}'}',
                createdAt: '${row['created_at'] ?? row['needed_by'] ?? ''}'
                    .split('T')
                    .first,
                description:
                    '${row['request_type'] ?? 'Purchase'}-${row['explanation'] ?? row['party_name'] ?? ''} | ${row['category'] ?? ''}',
                category: row['category'] as String?,
                amount: (num.tryParse('${row['total_amount']}') ?? 0).round(),
                status: 'Waiting',
              ))
          .toList(),
      onRequestTap: (request) async {
        await Navigator.push(
            context,
            MaterialPageRoute<void>(
                builder: (_) =>
                    PurchaseRequestDetailScreen(id: request.id, owner: true)));
        await _load();
        await widget.onChanged?.call();
      },
      onViewAll: () async {
        await Navigator.push(
            context,
            MaterialPageRoute<void>(
                builder: (_) => const OwnerDocumentListScreen()));
        await _load();
        await widget.onChanged?.call();
      });
}
