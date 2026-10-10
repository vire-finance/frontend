import '../../../core/constants/expense_categories.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../presentation/owner/owner_card_form.dart';

/// Employee-visible cards are supplied by the access service; this starts empty.
class EmployeePocketRepository extends ChangeNotifier {
  EmployeePocketRepository._();
  static final instance = EmployeePocketRepository._();

  List<VireCardData> _accessibleCards = const [];
  List<VireCardData> get accessibleCards => List.unmodifiable(_accessibleCards);
  List<VirePocketData> _accessiblePockets = const [];
  List<VirePocketData> get accessiblePockets =>
      List.unmodifiable(_accessiblePockets);
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final responses = await Future.wait([
        ApiClient.instance.dio.get<List<dynamic>>('/cards'),
        ApiClient.instance.dio.get<List<dynamic>>('/pockets'),
      ]);
      final cardRows = responses[0].data ?? const [];
      final pocketRows = responses[1].data ?? const [];
      _accessibleCards = cardRows.map((row) {
        final card = Map<String, dynamic>.from(row as Map);
        final expiryMonth = (card['expiry_month'] as num?)?.toInt() ?? 0;
        final expiryYear = (card['expiry_year'] as num?)?.toInt() ?? 0;
        return VireCardData(
          id: '${card['id']}',
          name: '${card['name'] ?? ''}',
          pocketId: '${card['pocket_id']}',
          balance: _integer(card['balance']),
          limit: _integer(card['monthly_limit']),
          lastFour: '${card['last_four_digits'] ?? ''}',
          allowedCategories:
              (card['allowed_categories'] as List?)?.cast<String>() ??
                  expenseCategories,
          themeIndex: _themeIndex(card['theme'] as String?),
          locked: card['status'] != 'ACTIVE',
          blocked: card['status'] == 'NONACTIVE',
          usageType: card['usage_type'] as String? ?? 'LONG_TERM',
          expiresOn: DateTime.tryParse('${card['expires_on'] ?? ''}'),
          expiryYear: expiryYear > 0 ? expiryYear : null,
          expiryMonth: expiryMonth > 0 ? expiryMonth : null,
          singleUseConsumed: card['single_use_consumed_at'] != null,
        );
      }).toList(growable: false);
      _accessiblePockets = pocketRows.map((row) {
        final pocket = Map<String, dynamic>.from(row as Map);
        return VirePocketData(
          id: '${pocket['id']}',
          name: '${pocket['name'] ?? ''}',
          balance: _integer(pocket['remaining_amount']),
          limit: _integer(pocket['monthly_limit']),
          source: 'Backend',
          themeIndex: _themeIndex(pocket['theme'] as String?),
        );
      }).toList(growable: false);
    } catch (_) {
      _accessibleCards = const [];
      _accessiblePockets = const [];
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static int _integer(dynamic value) =>
      value is num ? value.round() : int.tryParse('$value') ?? 0;

  static int _themeIndex(String? theme) => switch (theme?.toUpperCase()) {
        'BLUE' => 1,
        'PURPLE' => 6,
        'GREEN' => 2,
        'ORANGE' => 0,
        'RED' => 3,
        'PINK' => 4,
        'BLACK' => 5,
        _ => 1,
      };
}
