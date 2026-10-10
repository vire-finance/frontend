import '../../../core/constants/expense_categories.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../presentation/owner/owner_card_form.dart';

class PocketRepository extends ChangeNotifier {
  PocketRepository._();
  static final instance = PocketRepository._();
  final _api = ApiClient.instance;
  final pockets = <VirePocketData>[];
  final cards = <VireCardData>[];
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final responses = await Future.wait<Response<dynamic>>([
        _api.dio.get<List<dynamic>>('/pockets'),
        _api.dio.get<List<dynamic>>('/cards'),
      ]);
      pockets
        ..clear()
        ..addAll((responses[0].data as List<dynamic>? ?? const []).map(
            (row) => _pocketFromApi(Map<String, dynamic>.from(row as Map))));
      cards
        ..clear()
        ..addAll((responses[1].data as List<dynamic>? ?? const [])
            .map((row) => _cardFromApi(Map<String, dynamic>.from(row as Map))));
    } catch (_) {
      pockets.clear();
      cards.clear();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<VireCardData> cardsForPocket(String id) =>
      cards.where((card) => card.pocketId == id).toList();

  VirePocketData? pocketById(String id) {
    for (final pocket in pockets) {
      if (pocket.id == id) return pocket;
    }
    return null;
  }

  Future<VirePocketData> createPocket(VirePocketData pocket) async {
    final response =
        await _api.dio.post<Map<String, dynamic>>('/pockets', data: {
      'name': pocket.name,
      'allocated_amount': pocket.limit,
      'monthly_limit': pocket.limit,
      'theme': _backendTheme(pocket.themeIndex),
    });
    final created = _pocketFromApi(Map<String, dynamic>.from(response.data!));
    pockets.insert(0, created);
    notifyListeners();
    return created;
  }

  Future<VireCardData> createCard(VireCardData card) async {
    final response = await _api.dio.post<Map<String, dynamic>>('/cards', data: {
      'pocket_id': card.pocketId,
      'name': card.name,
      'theme': _backendTheme(card.themeIndex),
      'initial_balance': card.balance,
      'monthly_limit': card.limit,
      'allowed_categories': card.allowedCategories,
    });
    final created = _cardFromApi(Map<String, dynamic>.from(response.data!));
    cards.insert(0, created);
    notifyListeners();
    return created;
  }

  Future<void> updateCardStatus(VireCardData card,
      {required bool locked}) async {
    final response = await _api.dio.patch<Map<String, dynamic>>(
        '/cards/${card.id}/status',
        data: {'status': locked ? 'FROZEN' : 'ACTIVE'});
    _storeCard(_cardFromApi(Map<String, dynamic>.from(response.data!)));
  }

  void _storeCard(VireCardData card) {
    final index = cards.indexWhere((item) => item.id == card.id);
    if (index >= 0) cards[index] = card;
    notifyListeners();
  }

  Future<void> updateCardSettings(VireCardData card,
      {required DateTime expiresOn,
      required String usageType,
      required bool blocked}) async {
    final date =
        '${expiresOn.year.toString().padLeft(4, '0')}-${expiresOn.month.toString().padLeft(2, '0')}-${expiresOn.day.toString().padLeft(2, '0')}';
    final previousExpiry = card.expiresOn ??
        (card.expiryYear != null && card.expiryMonth != null
            ? DateTime(card.expiryYear!, card.expiryMonth! + 1, 0)
            : null);
    final response =
        await _api.dio.patch<Map<String, dynamic>>('/cards/${card.id}', data: {
      if (previousExpiry != expiresOn) 'expires_on': date,
      'usage_type': usageType,
      'blocked': blocked,
    });
    _storeCard(_cardFromApi(Map<String, dynamic>.from(response.data!)));
  }

  Future<List<Map<String, dynamic>>> employees() async {
    final response =
        await _api.dio.get<List<dynamic>>('/api/v1/workspace/employees');
    return (response.data ?? const [])
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> cardEmployees(String cardId) async {
    final response = await _api.dio.get<Map<String, dynamic>>('/cards/$cardId');
    return (response.data?['employees'] as List<dynamic>? ?? const [])
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<void> setCardEmployeeAccess(String cardId, String employeeId,
      {required bool enabled}) async {
    if (enabled) {
      await _api.dio.put<void>('/cards/$cardId/employees/$employeeId');
    } else {
      await _api.dio.delete<void>('/cards/$cardId/employees/$employeeId');
    }
  }

  Future<VireCardData> loadCardDetail(String cardId) async {
    final response = await _api.dio.get<Map<String, dynamic>>('/cards/$cardId');
    final card = _cardFromApi(Map<String, dynamic>.from(response.data!));
    final index = cards.indexWhere((item) => item.id == cardId);
    if (index >= 0) cards[index] = card;
    notifyListeners();
    return card;
  }

  Future<Map<String, dynamic>> pocketAnalysis(String pocketId) async {
    final response =
        await _api.dio.get<Map<String, dynamic>>('/pockets/$pocketId/analysis');
    return response.data ?? const {};
  }

  Future<void> toggleLock(VireCardData card) =>
      updateCardStatus(card, locked: !card.locked);

  static VirePocketData _pocketFromApi(Map<String, dynamic> row) =>
      VirePocketData(
        id: '${row['id']}',
        name: '${row['name'] ?? ''}',
        balance: _integer(row['remaining_amount']),
        limit: _integer(row['monthly_limit'] ?? row['allocated_amount']),
        source: 'Main Fund Account',
        themeIndex: _themeIndex(row['theme'] as String?),
      );

  static VireCardData _cardFromApi(Map<String, dynamic> row) => VireCardData(
        id: '${row['id']}',
        name: '${row['name'] ?? ''}',
        pocketId: '${row['pocket_id']}',
        balance: _integer(row['balance']),
        limit: _integer(row['monthly_limit']),
        lastFour: '${row['last_four_digits'] ?? '••••'}',
        allowedCategories:
            (row['allowed_categories'] as List?)?.cast<String>() ??
                expenseCategories,
        themeIndex: _themeIndex(row['theme'] as String?),
        locked: row['status'] != 'ACTIVE',
        blocked: row['status'] == 'NONACTIVE',
        usageType: row['usage_type'] as String? ?? 'LONG_TERM',
        expiresOn: DateTime.tryParse('${row['expires_on'] ?? ''}'),
        singleUseConsumed: row['single_use_consumed_at'] != null,
        maskedNumber: row['masked_number'] as String?,
        simulatedCardNumber: row['simulated_card_number'] as String?,
        expiryMonth: (row['expiry_month'] as num?)?.toInt(),
        expiryYear: (row['expiry_year'] as num?)?.toInt(),
        cvv: row['cvv'] as String?,
      );

  static int _integer(dynamic value) =>
      value is num ? value.round() : int.tryParse('$value') ?? 0;
  static String _backendTheme(int index) => switch (index) {
        0 => 'ORANGE',
        1 => 'BLUE',
        2 => 'GREEN',
        3 => 'RED',
        4 => 'PINK',
        5 => 'BLACK',
        6 => 'PURPLE',
        _ => 'BLUE',
      };
  static int _themeIndex(String? theme) => switch (theme?.toUpperCase()) {
        'ORANGE' => 0,
        'BLUE' => 1,
        'GREEN' => 2,
        'RED' => 3,
        'PINK' => 4,
        'BLACK' => 5,
        'PURPLE' => 6,
        _ => 1,
      };
}
