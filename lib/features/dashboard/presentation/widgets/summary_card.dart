import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard(
      {required this.icon,
      required this.title,
      required this.child,
      this.trailing,
      super.key});
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.grey50),
            borderRadius: BorderRadius.circular(20)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(icon, color: AppColors.blue500, size: 22),
            const SizedBox(width: 9),
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: AppColors.blue500,
                        fontSize: 16,
                        fontWeight: FontWeight.w700))),
            if (trailing != null) trailing!
          ]),
          const SizedBox(height: 14),
          child,
        ]),
      );
}
