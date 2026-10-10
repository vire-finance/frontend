import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:vire/features/dashboard/data/dashboard_model.dart';
import 'package:vire/features/dashboard/data/dashboard_repository.dart';
import 'package:vire/features/dashboard/data/spending_insights_repository.dart';
import 'package:vire/features/dashboard/providers/dashboard_provider.dart';

class DashboardStub implements DashboardRepository {
  @override
  Future<DashboardData> loadOwnerDashboard() async =>
      const DashboardData(monthlyLimit: 200000);
}

class PendingInsights extends SpendingInsightsRepository {
  final result = Completer<SpendingInsights>();
  int calls = 0;
  @override
  Future<SpendingInsights> generate({bool force = false}) {
    calls++;
    return result.future;
  }
}

void main() {
  test('dashboard loads without waiting for AI and then displays its summary',
      () async {
    final insights = PendingInsights();
    final provider =
        DashboardProvider(DashboardStub(), insightsRepository: insights);
    await provider.load();
    expect(provider.data?.monthlyLimit, 200000);
    expect(provider.isLoading, isFalse);
    expect(provider.isGeneratingInsights, isTrue);
    expect(insights.calls, 1);
    await provider.load();
    expect(insights.calls, 1);
    insights.result.complete(const SpendingInsights(
        available: true, summary: 'Ringkasan AI aktual.'));
    await Future<void>.delayed(Duration.zero);
    expect(provider.aiSummary, 'Ringkasan AI aktual.');
    expect(provider.isGeneratingInsights, isFalse);
    expect(provider.insightsFailed, isFalse);
    provider.dispose();
  });

  test('leaving dashboard during AI generation safely handles completion',
      () async {
    final insights = PendingInsights();
    final provider =
        DashboardProvider(DashboardStub(), insightsRepository: insights);
    await provider.load();
    provider.dispose();
    insights.result.complete(const SpendingInsights(available: false));
    await Future<void>.delayed(Duration.zero);
  });
}
