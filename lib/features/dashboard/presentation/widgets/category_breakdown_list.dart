import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../data/dashboard_model.dart';

class CategoryBreakdownList extends StatelessWidget {
  const CategoryBreakdownList(
      {required this.categories, this.showAmounts = false, super.key});
  final bool showAmounts;
  final List<SpendingCategory> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 22),
          child: Center(
              child: Text(
                  'Spending categories will appear when data is available.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grey500))));
    }
    if (showAmounts) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final category in categories)
          Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 5),
                    Row(children: [
                      Expanded(
                          child: Text(formatIdrInput(category.amount),
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.grey700))),
                      Text('${(category.share * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.blue500,
                              fontWeight: FontWeight.w600))
                    ]),
                    const SizedBox(height: 8),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                            value: category.share.clamp(0, 1).toDouble(),
                            minHeight: 5,
                            backgroundColor: AppColors.grey100,
                            valueColor: AlwaysStoppedAnimation(category.color)))
                  ]))
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final category in categories)
        Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(category.name,
                        style: const TextStyle(fontSize: 12))),
                Text('${(category.share * 100).toStringAsFixed(1)}%',
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.grey700))
              ]),
              const SizedBox(height: 5),
              ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                      value: category.share.clamp(0, 1).toDouble(),
                      minHeight: 5,
                      backgroundColor: AppColors.grey100,
                      valueColor: AlwaysStoppedAnimation(category.color)))
            ])),
    ]);
  }
}

class SpendingDonut extends StatelessWidget {
  const SpendingDonut({required this.categories, super.key});
  final List<SpendingCategory> categories;

  @override
  Widget build(BuildContext context) => SizedBox(
      width: 112,
      height: 112,
      child: CustomPaint(
          painter: _DonutPainter(categories),
          child: Center(
              child: Text(
                  categories.isEmpty
                      ? '—'
                      : '${(categories.fold<double>(0, (sum, item) => sum + item.share) * 100).round()}%',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey700)))));
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.categories);
  final List<SpendingCategory> categories;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = Paint()
      ..color = AppColors.blue50
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24;
    canvas.drawArc(rect.deflate(12), 0, 6.2832, false, base);
    if (categories.isEmpty) return;
    var start = -1.5708;
    for (final category in categories) {
      final sweep = category.share.clamp(0, 1).toDouble() * 6.2832;
      final paint = Paint()
        ..color = category.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect.deflate(12), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.categories != categories;
}
