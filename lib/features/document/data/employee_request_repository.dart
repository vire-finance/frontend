import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import 'document_model.dart';
import 'document_repository.dart';
import 'employee_request_model.dart';

class EmployeeRequestRepository extends ChangeNotifier {
  EmployeeRequestRepository._() {
    DocumentRepository.instance.addListener(_syncOwnerStatus);
  }
  static final instance = EmployeeRequestRepository._();
  final _api = ApiClient.instance;
  final List<EmployeePaymentRequest> _requests = [];
  List<EmployeePaymentRequest> get requests => List.unmodifiable(_requests);
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  final Map<String, String> _unreadNotificationByRequest = {};

  String? unreadNotificationFor(String requestId) =>
      _unreadNotificationByRequest[requestId];

  Future<void> markNotificationRead(String notificationId) async {
    await _api.dio.patch<void>('/notifications/$notificationId/read');
    _unreadNotificationByRequest.removeWhere((_, id) => id == notificationId);
    notifyListeners();
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response =
          await _api.dio.get<Map<String, dynamic>>('/fund-requests');
      final rows = response.data?['items'] as List<dynamic>? ?? const [];
      _requests
        ..clear()
        ..addAll(
            rows.map((row) => _fromApi(Map<String, dynamic>.from(row as Map))));
      try {
        final notifications = await _api.dio.get<Map<String, dynamic>>(
          '/notifications',
          queryParameters: {'unread_only': true, 'limit': 100},
        );
        _unreadNotificationByRequest.clear();
        final notificationRows =
            notifications.data?['items'] as List<dynamic>? ?? const [];
        for (final item in notificationRows) {
          final notification = Map<String, dynamic>.from(item as Map);
          final requestId = notification['request_id'];
          if (requestId != null &&
              '${notification['title']}'.toLowerCase().contains('tolak')) {
            _unreadNotificationByRequest['$requestId'] =
                '${notification['id']}';
          }
        }
      } on DioException {
        // Request statuses remain available if the notification endpoint is offline.
      }
      _mirrorIntoLocalOwnerDocuments();
    } catch (_) {
      _requests.clear();
      _unreadNotificationByRequest.clear();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<EmployeePaymentRequest> submit(EmployeePaymentRequest request) async {
    final draftResponse = await _api.dio.post<Map<String, dynamic>>(
      '/fund-requests',
      data: {
        'pocket_id': request.pocketId,
        'explanation': request.explanation,
        'request_type': 'PURCHASE',
        'category': request.requestType,
        'party_name': request.partyName,
        'total_amount': request.amount,
        'needed_by': request.neededAt.toUtc().toIso8601String(),
      },
    );
    final draft = Map<String, dynamic>.from(draftResponse.data!);
    final id = '${draft['id']}';
    if (request.ocrDocumentId != null) {
      await _api.dio.post<void>(
        '/fund-requests/$id/documents',
        data: {'document_id': request.ocrDocumentId},
      );
    }
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/fund-requests/$id/submit',
      data: {'allow_failed_ocr': request.allowFailedOcr},
    );
    final submitted = _fromApi(Map<String, dynamic>.from(response.data!));
    _upsert(submitted);
    return submitted;
  }

  Future<EmployeePaymentRequest> detail(String id) async {
    final response =
        await _api.dio.get<Map<String, dynamic>>('/fund-requests/$id');
    return _fromApi(Map<String, dynamic>.from(response.data!));
  }

  void add(EmployeePaymentRequest request) => _upsert(request);

  void updateStatus(String id, EmployeeRequestStatus status, {String? reason}) {
    final index = _requests.indexWhere((request) => request.id == id);
    if (index < 0) return;
    _requests[index] = _requests[index].withStatus(status, reason: reason);
    notifyListeners();
  }

  void _upsert(EmployeePaymentRequest request) {
    _requests.removeWhere((item) => item.id == request.id);
    _requests.insert(0, request);
    DocumentRepository.instance.add(DocumentData(
      id: request.id,
      reference: request.reference,
      amount: request.amount,
      date: request.neededAt,
      type: request.requestType,
      category: request.requestType,
      explanation: request.explanation,
      partyName: request.partyName,
      requestedBy: 'Employee',
      requestedByRole: 'Employee',
      declineReason: request.rejectionReason,
    ));
    notifyListeners();
  }

  void _mirrorIntoLocalOwnerDocuments() {
    for (final request in _requests) {
      final status = switch (request.status) {
        EmployeeRequestStatus.waiting => DocumentStatus.waiting,
        EmployeeRequestStatus.rejected => DocumentStatus.rejected,
        EmployeeRequestStatus.accepted => DocumentStatus.accepted,
      };
      DocumentRepository.instance.add(DocumentData(
        id: request.id,
        reference: request.reference,
        amount: request.amount,
        status: status,
        date: request.neededAt,
        type: request.requestType,
        category: request.requestType,
        explanation: request.explanation,
        partyName: request.partyName,
        requestedBy: 'Employee',
        requestedByRole: 'Employee',
        declineReason: request.rejectionReason,
      ));
    }
  }

  void _syncOwnerStatus() {
    final documents = DocumentRepository.instance.documents;
    var changed = false;
    for (var index = 0; index < _requests.length; index++) {
      final request = _requests[index];
      final matches = documents.where((document) => document.id == request.id);
      if (matches.isEmpty) continue;
      final document = matches.first;
      final status = switch (document.status) {
        DocumentStatus.waiting => EmployeeRequestStatus.waiting,
        DocumentStatus.rejected => EmployeeRequestStatus.rejected,
        DocumentStatus.accepted ||
        DocumentStatus.paid =>
          EmployeeRequestStatus.accepted,
      };
      if (request.status != status ||
          request.rejectionReason != document.declineReason) {
        _requests[index] =
            request.withStatus(status, reason: document.declineReason);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  static EmployeePaymentRequest _fromApi(Map<String, dynamic> row) {
    final status = switch ('${row['status']}') {
      'REJECTED' => EmployeeRequestStatus.rejected,
      'APPROVED' || 'COMPLETED' => EmployeeRequestStatus.accepted,
      _ => EmployeeRequestStatus.waiting,
    };
    final type = switch ('${row['request_type']}') {
      'CASH_ADVANCE' => 'Cash Advance',
      'PURCHASE' => 'Purchase',
      _ => 'Other',
    };
    return EmployeePaymentRequest(
      id: '${row['id']}',
      reference: '${row['display_id'] ?? row['id']}',
      pocketId: '${row['pocket_id']}',
      explanation: '${row['explanation'] ?? ''}',
      requestType: row['category'] as String? ?? type,
      partyName: '${row['party_name'] ?? ''}',
      amount: _integer(row['total_amount']),
      neededAt: _date(row['needed_by']),
      createdAt: _date(row['created_at']),
      status: status,
      rejectionReason: row['rejection_reason'] as String?,
    );
  }

  static int _integer(dynamic value) =>
      value is num ? value.round() : int.tryParse('$value') ?? 0;
  static DateTime _date(dynamic value) =>
      DateTime.tryParse('$value')?.toLocal() ?? DateTime.now();
}
