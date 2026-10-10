import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money_formatter.dart';
import '../data/dashboard_model.dart';
import '../data/spending_insights_repository.dart';
import 'widgets/spending_category_chart.dart';
import 'widgets/generating_analysis_text.dart';

class AnalyticsDetailScreen extends StatefulWidget {
  const AnalyticsDetailScreen(
      {required this.data, this.insightsRepository, super.key});
  final DashboardData data;
  final SpendingInsightsRepository? insightsRepository;
  @override
  State<AnalyticsDetailScreen> createState() => _AnalyticsDetailScreenState();
}

class _AnalyticsDetailScreenState extends State<AnalyticsDetailScreen> {
  SpendingInsights? _insights;
  bool _loading = true;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate({bool force = false}) async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final result =
          await (widget.insightsRepository ?? ApiSpendingInsightsRepository())
              .generate(force: force);
      if (mounted) setState(() => _insights = result);
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _insights = null;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _panel(List<Widget> children) => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.grey50)),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children));
  Widget _heading(String text) => Text(text,
      style: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.blue500));
  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final spent =
        data.spendingCategories.fold<int>(0, (sum, item) => sum + item.amount);
    final limit = data.monthlyLimit;
    final utilization = limit != null && limit > 0 ? spent * 100 / limit : null;
    final available = !_failed && _insights?.available == true;
    final unavailable = _insights?.reason == 'LLM_NOT_CONFIGURED'
        ? 'AI analysis is not active yet.'
        : 'AI analysis is unavailable right now. Please try again.';
    return Scaffold(
        backgroundColor: AppColors.basicWhite,
        appBar: AppBar(
            title: const Text('Spending Analytics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            centerTitle: true,
            backgroundColor: AppColors.basicWhite,
            foregroundColor: AppColors.blue900,
            elevation: 0),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(20), children: [
          _panel([
            _heading('Spending categories'),
            const SizedBox(height: 18),
            SpendingCategoryChart(categories: data.spendingCategories),
            const Divider(),
            const Text('Total Spent',
                style: TextStyle(color: AppColors.grey700)),
            const SizedBox(height: 6),
            Text(formatIdrInput(spent),
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue900)),
            const SizedBox(height: 4),
            Text(
                utilization == null
                    ? 'Monthly limit is not available.'
                    : '${utilization.toStringAsFixed(1)}% of the ${formatIdrInput(limit!)} monthly limit',
                style: const TextStyle(fontSize: 13, color: AppColors.grey500))
          ]),
          const SizedBox(height: 18),
          _panel([
            Row(children: [
              const Icon(Icons.auto_awesome,
                  color: AppColors.blue500, size: 20),
              const SizedBox(width: 8),
              Expanded(child: _heading('AI Analysis')),
              IconButton(
                  tooltip: 'Refresh analysis',
                  onPressed: () {
                    if (_loading) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'Analysis is still running. Please wait for it to finish.')));
                    } else {
                      _generate(force: true);
                    }
                  },
                  color: AppColors.blue500,
                  icon: const Icon(Icons.refresh, size: 22))
            ]),
            const SizedBox(height: 18),
            _heading('Quick Summary'),
            const SizedBox(height: 8),
            if (_loading)
              const GeneratingAnalysisText(
                  color: AppColors.blue300, fontSize: 14)
            else
              Text(
                  available
                      ? _insights!.summary ?? 'No summary returned.'
                      : unavailable,
                  style: const TextStyle(
                      fontSize: 14, height: 1.5, color: AppColors.grey700)),
            if (!_loading) ...[
              const SizedBox(height: 20),
              _heading('Recommendation'),
              const SizedBox(height: 8),
              if (available)
                for (final recommendation in _insights!.recommendations)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.arrow_forward,
                                size: 18, color: AppColors.blue500),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(recommendation,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: AppColors.grey700)))
                          ]))
              else
                const Text(
                    'Recommendations will appear when AI analysis is available.',
                    style: TextStyle(fontSize: 13, color: AppColors.grey500)),
            ],
          ])
        ])));
  }
}
