import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../pocket/presentation/owner/owner_card_form.dart';
import 'transaction_model.dart';

class TransactionRepository extends ChangeNotifier {
  TransactionRepository._();
  static final instance = TransactionRepository._();
  final List<TransactionData> _transactions = [];
  List<TransactionData> get transactions => List.unmodifiable(_transactions);
  final _api = ApiClient.instance;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> load({String? cardId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/history',
        queryParameters: {
          'offset': 0,
          'limit': 100,
          if (cardId != null) 'card_id': cardId
        },
      );
      final rows = response.data?['items'] as List<dynamic>? ?? const [];
      _transactions
        ..clear()
        ..addAll(
            rows.map((row) => _fromApi(Map<String, dynamic>.from(row as Map))));
    } catch (_) {
      _transactions.clear();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TransactionData> createCardPayment({
    required VireCardData card,
    required String title,
    required int amount,
    required String actionToken,
    String category = 'Others',
    String paymentMethod = 'QRIS',
    String? recipientAccount,
    String? idempotencyKey,
  }) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/transactions',
      data: {
        'card_id': card.id,
        'amount': amount,
        'description': title.trim(),
        'category': category,
        'payment_method': paymentMethod,
        if (recipientAccount != null) 'recipient_account': recipientAccount,
      },
      options: Options(headers: {
        'Idempotency-Key': idempotencyKey ?? ApiClient.newIdempotencyKey(),
        'X-Action-Token': actionToken,
      }),
    );
    final data = Map<String, dynamic>.from(response.data!);
    if (data['status'] != 'APPROVED') {
      throw StateError(
          '${data['failure_reason'] ?? 'Pembayaran tidak berhasil.'}');
    }
    // A committed payment must remain successful even if refreshing History fails.
    await load().catchError((_) {});
    return _transactions.firstWhere(
      (transaction) => transaction.id == '${data['id']}',
      orElse: () =>
          _fromApi({...data, 'card_name': card.name, 'category': category}),
    );
  }

  void add(TransactionData transaction) {
    _transactions.insert(0, transaction);
    notifyListeners();
  }

  static TransactionData _fromApi(Map<String, dynamic> row) => TransactionData(
        id: '${row['id']}',
        title: '${row['party_name'] ?? row['description'] ?? ''}',
        amount: _integer(row['amount']),
        sourceAccount: '${row['card_name'] ?? ''}',
        dateTime: _date(row['processed_at'] ?? row['created_at']),
        paymentMethod:
            '${row['payment_method'] ?? row['transaction_type'] ?? 'CARD_PAYMENT'}',
        requestId: row['fund_request_id'] as String?,
        category: row['category'] as String?,
        transactionId: '${row['id']}',
        status: '${row['status'] ?? 'APPROVED'}',
        cardId: row['card_id'] == null ? null : '${row['card_id']}',
        pocketId: row['pocket_id'] == null ? null : '${row['pocket_id']}',
        failureReason: row['failure_reason'] as String?,
      );

  static int _integer(dynamic value) =>
      value is num ? value.round() : int.tryParse('$value') ?? 0;
  static DateTime _date(dynamic value) => DateTime.parse('$value').toLocal();
}
