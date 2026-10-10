import '../../../../shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/dashboard_model.dart';
import 'ai_analysis_banner.dart';
import 'category_breakdown_list.dart';
import 'summary_card.dart';

class SpendingAnalyticsCard extends StatefulWidget {
  const SpendingAnalyticsCard(
      {required this.data,
      this.onExport,
      this.onViewDetails,
      this.aiSummary,
      this.isAiLoading = false,
      this.hasAiError = false,
      this.onRefreshAi,
      super.key});
  final DashboardData data;
  final String? aiSummary;
  final bool isAiLoading;
  final bool hasAiError;
  final VoidCallback? onRefreshAi;
  final VoidCallback? onExport;
  final VoidCallback? onViewDetails;

  @override
  State<SpendingAnalyticsCard> createState() => _SpendingAnalyticsCardState();
}

class _SpendingAnalyticsCardState extends State<SpendingAnalyticsCard> {
  String _period = 'This Month';
  String _type = 'Expenses';

  @override
  Widget build(BuildContext context) => SummaryCard(
        icon: Icons.analytics_outlined,
        title: 'Spending Analytics',
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
                child: _selector(_period, const ['This Month', 'Last Month'],
                    (value) => setState(() => _period = value))),
            const SizedBox(width: 8),
            Expanded(
                child: _selector(_type, const ['Expenses', 'Income'],
                    (value) => setState(() => _type = value)))
          ]),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SpendingDonut(categories: widget.data.spendingCategories),
            const SizedBox(width: 12),
            Expanded(
                child: widget.data.spendingCategories.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Text(
                            'Category breakdown will appear here when spending data is available.',
                            style: TextStyle(
                                color: AppColors.grey500, fontSize: 12)))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            const Text('Category',
                                style: TextStyle(
                                    color: AppColors.orange600,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11)),
                            const SizedBox(height: 8),
                            CategoryBreakdownList(
                                categories: widget.data.spendingCategories)
                          ]))
          ]),
          const SizedBox(height: 8),
          AiAnalysisBanner(
              message: widget.aiSummary ?? widget.data.aiInsight,
              isLoading: widget.isAiLoading,
              hasError: widget.hasAiError,
              onRefresh: widget.onRefreshAi),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: widget.onExport,
                    icon: const Icon(Icons.download_outlined, size: 16),
                    label: const Text('Export'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.blue500,
                        side: const BorderSide(color: AppColors.blue500)))),
            const SizedBox(width: 10),
            Expanded(
                child: FilledButton.icon(
                    onPressed: widget.onViewDetails,
                    icon: const Icon(Icons.article_outlined, size: 16),
                    label: const Text('View Details'),
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.blue400)))
          ]),
        ]),
      );

  Widget _selector(
          String value, List<String> options, ValueChanged<String> onChanged) =>
      AppDropdownField<String>(
          value: value,
          decoration: const AppInputDecoration(),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.blue500),
          items: options
              .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 11))))
              .toList(),
          onChanged: (next) {
            if (next != null) onChanged(next);
          });
}
