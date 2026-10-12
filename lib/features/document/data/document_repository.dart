import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../history/data/transaction_repository.dart';
import '../../pocket/data/pocket_repository.dart';
import 'document_model.dart';

class DocumentRepository extends ChangeNotifier {
  DocumentRepository._();
  static final instance = DocumentRepository._();
  final _api = ApiClient.instance;
  final List<DocumentData> _documents = [];
  List<DocumentData> get documents => List.unmodifiable(_documents);
  int _generation = 0;

  /// Drops cached account data so a later session never sees it.
  void clear() {
    _generation++;
    _documents.clear();
    notifyListeners();
  }

  Future<List<DocumentData>> loadDocuments() async {
    final requestGeneration = ++_generation;
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
          '/fund-requests',
          queryParameters: {'limit': 200});
      if (requestGeneration != _generation) return documents;
      final rows = response.data?['items'] as List<dynamic>? ?? const [];
      _documents
        ..clear()
        ..addAll(rows
            .map((item) => _fromApi(Map<String, dynamic>.from(item as Map))));
      return documents;
    } catch (_) {
      if (requestGeneration != _generation) return documents;
      _documents.clear();
      rethrow;
    } finally {
      if (requestGeneration == _generation) notifyListeners();
    }
  }

  Future<DocumentData> loadDetail(String id) async {
    final requestGeneration = _generation;
    final response =
        await _api.dio.get<Map<String, dynamic>>('/fund-requests/$id');
    final detail = _fromApi(Map<String, dynamic>.from(response.data!));
    if (requestGeneration == _generation) add(detail);
    return detail;
  }

  Future<void> rejectRequest(
      String id, String reason, String actionToken) async {
    final requestGeneration = _generation;
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/fund-requests/$id/reject',
      data: {'reason': reason},
      options: Options(headers: {'X-Action-Token': actionToken}),
    );
    if (requestGeneration != _generation) return;
    add(_fromApi(Map<String, dynamic>.from(response.data!)));
  }

  Future<void> approveRequest(
      String id, String cardId, String actionToken) async {
    await _api.dio.post<Map<String, dynamic>>(
      '/fund-requests/$id/approve',
      data: {'card_id': cardId},
      options: Options(headers: {
        'Idempotency-Key': ApiClient.newIdempotencyKey(),
        'X-Action-Token': actionToken,
      }),
    );
    await Future.wait<void>([
      loadDocuments().then((_) {}),
      PocketRepository.instance.load(),
      TransactionRepository.instance.load(),
    ]);
  }

  void add(DocumentData document) {
    _documents.removeWhere((item) => item.id == document.id);
    _documents.insert(0, document);
    notifyListeners();
  }

  void updateStatus(String id, DocumentStatus status, {String? declineReason}) {
    final index = _documents.indexWhere((document) => document.id == id);
    if (index < 0) return;
    _documents[index] = _documents[index]
        .copyWith(status: status, declineReason: declineReason);
    notifyListeners();
  }

  static DocumentData _fromApi(Map<String, dynamic> row) {
    final requestStatus = '${row['status']}';
    final status = switch (requestStatus) {
      'REJECTED' => DocumentStatus.rejected,
      'APPROVED' || 'COMPLETED' => DocumentStatus.accepted,
      _ => DocumentStatus.waiting,
    };
    final requester = row['requester'] is Map
        ? Map<String, dynamic>.from(row['requester'] as Map)
        : const <String, dynamic>{};
    final documents = row['documents'] as List<dynamic>? ?? const [];
    final attached = documents.isEmpty
        ? null
        : Map<String, dynamic>.from(documents.first as Map);
    final analysis = row['ai_analysis'];
    final analysisText =
        analysis is Map ? analysis['summary'] as String? : analysis as String?;
    return DocumentData(
      id: '${row['id']}',
      reference: '${row['display_id'] ?? row['id']}',
      amount: _integer(row['total_amount']),
      pocketId: '${row['pocket_id']}',
      status: status,
      date: _date(row['needed_by']),
      type: row['category'] as String? ??
          _requestTypeLabel('${row['request_type']}'),
      category: row['category'] as String? ?? 'Others',
      explanation: row['explanation'] as String?,
      fileName: attached?['original_filename'] as String?,
      fileId: attached == null ? null : '${attached['id']}',
      fileDate: attached == null ? null : _date(attached['created_at']),
      partyName: row['party_name'] as String?,
      requestedBy: requester['name'] as String?,
      requestedByRole: 'Employee',
      aiAnalysis: analysisText,
      declineReason: row['rejection_reason'] as String?,
    );
  }

  static String _requestTypeLabel(String value) => switch (value) {
        'CASH_ADVANCE' => 'Cash Advance',
        'PURCHASE' => 'Purchase',
        _ => 'Other',
      };
  static int _integer(dynamic value) =>
      value is num ? value.round() : int.tryParse('$value') ?? 0;
  static DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.tryParse('$value')?.toLocal();
}
