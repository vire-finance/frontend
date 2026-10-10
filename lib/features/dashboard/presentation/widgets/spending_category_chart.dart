import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../data/dashboard_model.dart';

class SpendingCategoryChart extends StatelessWidget {
  const SpendingCategoryChart({required this.categories, super.key});
  final List<SpendingCategory> categories;

  @override
  Widget build(BuildContext context) {
    final active = categories.where((category) => category.amount > 0).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    if (active.isEmpty) {
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text('No expenses this month.',
              style: TextStyle(color: AppColors.grey500)));
    }
    final highest = active.first.amount;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      LayoutBuilder(builder: (context, constraints) {
        final width = math.max(constraints.maxWidth, active.length * 72.0);
        return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
                width: width,
                child: Column(children: [
                  SizedBox(
                      height: 180,
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final category in active)
                              Expanded(
                                  child: Semantics(
                                      label:
                                          '${category.name}: ${formatIdrInput(category.amount)}',
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                                '${(category.share * 100).toStringAsFixed(1)}%',
                                                style: TextStyle(
                                                    color: category.color,
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            const SizedBox(height: 8),
                                            Container(
                                                width: 38,
                                                height: category.amount /
                                                    highest *
                                                    145,
                                                decoration: BoxDecoration(
                                                    color: category.color,
                                                    borderRadius:
                                                        const BorderRadius
                                                            .vertical(
                                                            top:
                                                                Radius.circular(
                                                                    12))))
                                          ])))
                          ])),
                  const Divider(
                      height: 1, thickness: 1, color: AppColors.grey100),
                  const SizedBox(height: 8),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (final category in active)
                      Expanded(
                          child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: Text(
                                  category.name == 'Administration & Tax'
                                      ? 'Admin & Tax'
                                      : category.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 10, color: AppColors.grey700))))
                  ])
                ])));
      }),
      const SizedBox(height: 24),
      for (final category in active)
        Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(children: [
              Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: category.color.withAlpha(24),
                      shape: BoxShape.circle),
                  child: CustomPaint(
                      painter:
                          _CategoryIconPainter(category.name, category.color))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(category.name,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.grey700)),
                    const SizedBox(height: 5),
                    Text(formatIdrInput(category.amount),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue900))
                  ])),
              const SizedBox(width: 8),
              Text('${(category.share * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue900))
            ]))
    ]);
  }
}

// Original vector paths, drawn at any resolution without bitmap assets.
class _CategoryIconPainter extends CustomPainter {
  const _CategoryIconPainter(this.category, this.color);
  final String category;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), stroke);
    void box(double x, double y, double w, double h, [double radius = 1.5]) =>
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(x, y, w, h), Radius.circular(radius)),
            stroke);
    switch (category) {
      case 'Salary':
        box(2, 5, 20, 14, 2);
        canvas.drawCircle(const Offset(12, 12), 3, stroke);
        line(5, 9, 5, 15);
        line(19, 9, 19, 15);
        break;
      case 'Operational':
        canvas.drawCircle(const Offset(12, 12), 6, stroke);
        canvas.drawCircle(const Offset(12, 12), 2.5, stroke);
        for (var i = 0; i < 8; i++) {
          final angle = i * math.pi / 4;
          line(12 + math.cos(angle) * 6, 12 + math.sin(angle) * 6,
              12 + math.cos(angle) * 9, 12 + math.sin(angle) * 9);
        }
        break;
      case 'Production':
        canvas.drawPath(
            Path()
              ..moveTo(3, 21)
              ..lineTo(3, 4)
              ..lineTo(7, 4)
              ..lineTo(7, 12)
              ..lineTo(13, 8)
              ..lineTo(13, 13)
              ..lineTo(21, 9)
              ..lineTo(21, 21)
              ..close(),
            stroke);
        line(7, 17, 9, 17);
        line(12, 17, 14, 17);
        line(17, 17, 19, 17);
        break;
      case 'Marketing':
        canvas.drawPath(
            Path()
              ..moveTo(3, 9)
              ..lineTo(9, 9)
              ..lineTo(18, 4)
              ..lineTo(18, 18)
              ..lineTo(9, 14)
              ..lineTo(3, 14)
              ..close(),
            stroke);
        line(8, 14, 10, 21);
        line(10, 21, 13, 21);
        line(13, 21, 11, 15);
        line(21, 8, 23, 7);
        line(21, 14, 23, 15);
        break;
      case 'Emergency':
        canvas.drawPath(
            Path()
              ..moveTo(12, 2)
              ..lineTo(21, 6)
              ..quadraticBezierTo(21, 17, 12, 22)
              ..quadraticBezierTo(3, 17, 3, 6)
              ..close(),
            stroke);
        line(12, 8, 12, 16);
        line(8, 12, 16, 12);
        break;
      case 'Administration & Tax':
        canvas.drawPath(
            Path()
              ..moveTo(5, 2)
              ..lineTo(15, 2)
              ..lineTo(20, 7)
              ..lineTo(20, 22)
              ..lineTo(5, 22)
              ..close(),
            stroke);
        line(15, 2, 15, 7);
        line(15, 7, 20, 7);
        line(9, 17, 16, 10);
        canvas.drawCircle(const Offset(9, 10), 1.2, stroke);
        canvas.drawCircle(const Offset(16, 17), 1.2, stroke);
        break;
      default:
        box(3, 3, 7, 7);
        box(14, 3, 7, 7);
        box(3, 14, 7, 7);
        box(14, 14, 7, 7);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CategoryIconPainter oldDelegate) =>
      oldDelegate.category != category || oldDelegate.color != color;
}
