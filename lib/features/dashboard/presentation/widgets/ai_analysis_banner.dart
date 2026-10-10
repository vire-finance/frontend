import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'generating_analysis_text.dart';

class AiAnalysisBanner extends StatelessWidget {
  const AiAnalysisBanner(
      {this.message,
      this.isLoading = false,
      this.hasError = false,
      this.onRefresh,
      super.key});
  final String? message;
  final bool isLoading;
  final bool hasError;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final hasInsight = message != null && message!.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      decoration: BoxDecoration(
          color: const Color(0xFFFFEBEB),
          border: Border.all(color: AppColors.red300),
          borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.auto_awesome, color: AppColors.red500, size: 21),
          const SizedBox(width: 14),
          const Expanded(
              child: Text('AI Analysis',
                  style: TextStyle(
                      color: AppColors.red700,
                      fontWeight: FontWeight.w700,
                      fontSize: 12))),
          if (onRefresh != null)
            IconButton(
                onPressed: onRefresh,
                tooltip: 'Refresh analysis',
                visualDensity: VisualDensity.compact,
                color: AppColors.red500,
                icon: const Icon(Icons.refresh, size: 18))
        ]),
        const SizedBox(height: 5),
        Padding(
            padding: const EdgeInsets.only(left: 35),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (isLoading) ...[
                const GeneratingAnalysisText(),
                if (hasInsight) const SizedBox(height: 8),
              ],
              if (!isLoading || hasInsight)
                Text(
                    hasInsight
                        ? message!
                        : hasError
                            ? 'AI analysis is unavailable. Tap refresh to try again.'
                            : 'Your spending analysis will appear here.',
                    style: const TextStyle(
                        color: AppColors.red700, fontSize: 12, height: 1.5))
            ]))
      ]),
    );
  }
}
