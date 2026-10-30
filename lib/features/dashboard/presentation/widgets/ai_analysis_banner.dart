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
    final unavailable = hasError && !hasInsight;
    final tone = unavailable
        ? (
            background: const Color(0xFFFFEBEB),
            border: AppColors.red300,
            icon: AppColors.red500,
            title: AppColors.red700,
            text: AppColors.red700
          )
        : (
            background: AppColors.blue50,
            border: AppColors.blue200,
            icon: AppColors.blue500,
            title: AppColors.blue700,
            text: AppColors.blue700
          );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      decoration: BoxDecoration(
          color: tone.background,
          border: Border.all(color: tone.border),
          borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(Icons.auto_awesome, color: tone.icon, size: 21),
          const SizedBox(width: 14),
          Expanded(
              child: Text('AI Analysis',
                  style: TextStyle(
                      color: tone.title,
                      fontWeight: FontWeight.w700,
                      fontSize: 12))),
          if (onRefresh != null)
            IconButton(
                onPressed: onRefresh,
                tooltip: 'Refresh analysis',
                visualDensity: VisualDensity.compact,
                color: tone.icon,
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
                    style:
                        TextStyle(color: tone.text, fontSize: 12, height: 1.5))
            ]))
      ]),
    );
  }
}
