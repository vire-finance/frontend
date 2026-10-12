import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vire/core/network/api_client.dart';
import 'package:vire/features/dashboard/data/dashboard_model.dart';
import 'package:vire/features/dashboard/data/dashboard_repository.dart';
import 'package:vire/features/dashboard/presentation/widgets/spending_analytics_card.dart';

String expectedLastWibMonth() {
  final wib = DateTime.now().toUtc().add(const Duration(hours: 7));
  final year = wib.month == 1 ? wib.year - 1 : wib.year;
  final month = wib.month == 1 ? 12 : wib.month - 1;
  return '$year-${month.toString().padLeft(2, '0')}';
}

void main() {
  test('period label mapping incl. January boundary', () {
    expect(
        SpendingAnalyticsCard.spendingPeriodParam(
            'This Month', DateTime.utc(2026, 10, 12)),
        isNull);
    expect(
        SpendingAnalyticsCard.spendingPeriodParam(
            'Last Month', DateTime.utc(2026, 10, 12)),
        '2026-09');
    expect(
        SpendingAnalyticsCard.spendingPeriodParam(
            'Last Month', DateTime.utc(2026, 1, 5)),
        '2025-12');
    expect(
        SpendingAnalyticsCard.spendingPeriodParam(
            'Last Month', DateTime.utc(2026, 3, 1)),
        '2026-02');
  });

  testWidgets('UI-selected period reaches export and reload callbacks',
      (tester) async {
    String? exported = 'unset';
    String? reloaded = 'unset';
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SpendingAnalyticsCard(
      data: DashboardData.empty,
      onExport: (period) => exported = period,
      onPeriodChanged: (period) => reloaded = period,
    ))));

    final dropdowns = find.byType(DropdownButtonFormField<String>);
    expect(dropdowns, findsNWidgets(2));
    await tester.tap(dropdowns.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last Month').last);
    await tester.pumpAndSettle();
    expect(reloaded, expectedLastWibMonth());

    await tester.tap(find.widgetWithText(OutlinedButton, 'Export'));
    await tester.pumpAndSettle();
    expect(exported, expectedLastWibMonth());

    await tester.tap(dropdowns.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('This Month').last);
    await tester.pumpAndSettle();
    expect(reloaded, isNull);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Export'));
    await tester.pumpAndSettle();
    expect(exported, isNull);
  });

  test('repository forwards the selected period to the spending endpoint',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
    final dio = ApiClient.instance.dio;
    final previousAdapter = dio.httpClientAdapter;
    final spendingQueries = <Map<String, dynamic>>[];
    dio.httpClientAdapter = _Adapter((options) async {
      if (options.path == '/dashboard/spending') {
        spendingQueries.add(Map<String, dynamic>.from(
            options.queryParameters.map((k, v) => MapEntry(k, v))));
        return _json({
          'categories': [],
          'monthly_limit': 0,
        });
      }
      if (options.path == '/dashboard/pending-requests') {
        return _json({
          'items': [],
          'summary': {'waiting': 0}
        });
      }
      return _json({
        'name': 'Owner',
        'total_balance': 0,
        'recent_transactions': {'items': [], 'total': 0},
      });
    });
    addTearDown(() {
      dio.httpClientAdapter = previousAdapter;
      FlutterSecureStorage.setMockInitialValues({});
    });

    await ApiDashboardRepository().loadOwnerDashboard(period: '2026-09');
    expect(spendingQueries.single['period'], '2026-09');

    await ApiDashboardRepository().loadOwnerDashboard();
    expect(spendingQueries.last.containsKey('period'), isFalse);
  });
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);
  Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object data) =>
    ResponseBody.fromString(jsonEncode(data), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    });
