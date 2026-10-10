import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import 'dashboard_model.dart';

abstract interface class DashboardRepository {
  Future<DashboardData> loadOwnerDashboard();
}

class ApiDashboardRepository implements DashboardRepository {
  ApiDashboardRepository([ApiClient? api]) : _api = api ?? ApiClient.instance;
  final ApiClient _api;

  @override
  Future<DashboardData> loadOwnerDashboard() async {
    final responses = await Future.wait<Response<dynamic>>([
      _api.dio.get<Map<String, dynamic>>('/dashboard'),
      _api.dio.get<Map<String, dynamic>>('/dashboard/pending-requests',
          queryParameters: {'limit': 5}),
      _api.dio.get<Map<String, dynamic>>('/dashboard/spending'),
    ]);
    final summary = Map<String, dynamic>.from(responses[0].data as Map);
    final pendingData = Map<String, dynamic>.from(responses[1].data as Map);
    final spending = Map<String, dynamic>.from(responses[2].data as Map);
    final requestItems = pendingData['items'] as List<dynamic>? ?? const [];
    final transactionPage = Map<String, dynamic>.from(
        summary['recent_transactions'] as Map? ?? const {});
    final transactionItems =
        transactionPage['items'] as List<dynamic>? ?? const [];
    final categoryRows = spending['categories'] as List<dynamic>? ?? const [];

    return DashboardData(
      ownerName: summary['name'] as String?,
      totalBalance: _integer(summary['total_balance']),
      monthlyLimit: _integer(spending['monthly_limit']),
      pendingRequestCount: _integer(pendingData['summary'] is Map
          ? (pendingData['summary'] as Map)['waiting']
          : summary['pending_request_count']),
      transactionCount: _integer(transactionPage['total']),
      pendingRequests: requestItems.map((item) {
        final row = Map<String, dynamic>.from(item as Map);
        return PaymentRequest(
          id: '${row['id']}',
          reference: '${row['display_id'] ?? row['id']}',
          createdAt: _shortDate(row['created_at']),
          description: '${row['party_name'] ?? row['explanation'] ?? ''}',
          amount: _integer(row['total_amount']),
          status: '${row['status'] ?? ''}',
        );
      }).toList(growable: false),
      transactions: transactionItems.map((item) {
        final row = Map<String, dynamic>.from(item as Map);
        return DashboardTransaction(
          id: '${row['id']}',
          merchant: '${row['party_name'] ?? row['description'] ?? ''}',
          date: _shortDate(row['processed_at'] ?? row['created_at']),
          category: '${row['category'] ?? ''}',
          amount: _integer(row['amount']),
        );
      }).toList(growable: false),
      spendingCategories: categoryRows.map((item) {
        final row = Map<String, dynamic>.from(item as Map);
        return SpendingCategory(
          name: '${row['category'] ?? ''}',
          amount: _integer(row['amount']),
          share: ((row['percentage'] as num?)?.toDouble() ?? 0) / 100,
          color: _categoryColor('${row['category'] ?? ''}'),
        );
      }).toList(growable: false),
    );
  }

  static int _integer(dynamic value) =>
      value is num ? value.round() : int.tryParse('$value') ?? 0;
  static String _shortDate(dynamic value) {
    final date = DateTime.tryParse('$value')?.toLocal();
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static Color _categoryColor(String category) {
    const categoryColors = {
      'Salary': Color(0xFF3260CD),
      'Operational': Color(0xFF41C343),
      'Production': Color(0xFFF77F00),
      'Marketing': Color(0xFF8B5CF6),
      'Emergency': Color(0xFFEF4444),
      'Administration & Tax': Color(0xFF06B6D4),
      'Others': Color(0xFF64748B),
    };
    if (categoryColors.containsKey(category)) return categoryColors[category]!;
    const colors = [
      Color(0xFF3260CD),
      Color(0xFF41C343),
      Color(0xFFF77F00),
      Color(0xFFFF0000),
      Color(0xFFD62FC3)
    ];
    return colors[category.hashCode.abs() % colors.length];
  }
}
