import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vire/features/dashboard/data/dashboard_model.dart';
import 'package:vire/features/dashboard/data/spending_insights_repository.dart';
import 'package:vire/features/dashboard/presentation/analytics_detail_screen.dart';

class FakeInsights extends SpendingInsightsRepository {
  FakeInsights(this.result);
  final SpendingInsights result;
  int calls = 0;
  @override
  Future<SpendingInsights> generate({bool force = false}) async {
    calls++;
    return result;
  }
}

const data = DashboardData(monthlyLimit: 200000, spendingCategories: [
  SpendingCategory(
      name: 'Marketing', amount: 50000, share: 1, color: Colors.blue)
]);

void main() {
  test('AI response maps actual summary and recommended actions', () {
    final result = SpendingInsights.fromApi({
      'ai_analysis': {
        'available': true,
        'summary': 'Ringkasan dari model.',
        'insights': [
          {'recommended_action': 'Tinjau pengeluaran marketing.'}
        ]
      }
    });
    expect(result.summary, 'Ringkasan dari model.');
    expect(result.recommendations, ['Tinjau pengeluaran marketing.']);
  });

  testWidgets('detail displays rupiah, monthly percentage and AI next steps',
      (tester) async {
    final repo = FakeInsights(const SpendingInsights(
        available: true,
        summary: 'Ringkasan dari model.',
        recommendations: ['Tinjau pengeluaran marketing.']));
    await tester.pumpWidget(MaterialApp(
        home: AnalyticsDetailScreen(data: data, insightsRepository: repo)));
    await tester.pumpAndSettle();
    expect(repo.calls, 1);
    expect(find.text('IDR 50.000,00'), findsNWidgets(2));
    expect(find.text('25.0% of monthly limit'), findsOneWidget);
    expect(find.text('IDR 200.000,00'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(find.text('Quick Summary'), findsOneWidget);
    expect(find.text('Recommendation'), findsOneWidget);
    expect(find.text('Ringkasan dari model.'), findsOneWidget);
    expect(find.text('Tinjau pengeluaran marketing.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI unavailable is shown without inventing a narrative',
      (tester) async {
    final repo = FakeInsights(
        const SpendingInsights(available: false, reason: 'LLM_NOT_CONFIGURED'));
    await tester.pumpWidget(MaterialApp(
        home: AnalyticsDetailScreen(data: data, insightsRepository: repo)));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(find.text('AI analysis is not active yet.'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}
