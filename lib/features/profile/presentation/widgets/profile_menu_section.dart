import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ProfileMenuItem {
  const ProfileMenuItem({required this.icon, required this.label, this.onTap, this.isDestructive = false});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDestructive;
}

class ProfileMenuSection extends StatelessWidget {
  const ProfileMenuSection({required this.title, required this.items, super.key});
  final String title;
  final List<ProfileMenuItem> items;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(title, style: const TextStyle(color: AppColors.orange500, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: AppColors.white, border: Border.all(color: AppColors.grey50), borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  _ProfileMenuRow(item: items[index]),
                  if (index < items.length - 1) const Divider(height: 1, color: AppColors.grey50),
                ],
              ],
            ),
          ),
        ],
      );
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({required this.item});
  final ProfileMenuItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.isDestructive ? AppColors.red500 : AppColors.blue500;
    return InkWell(
      onTap: item.onTap,
      child: SizedBox(
        height: 46,
        child: Row(children: [
          Icon(item.icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(item.label, style: TextStyle(color: item.isDestructive ? AppColors.red500 : AppColors.grey700, fontSize: 14))),
          const Icon(Icons.chevron_right, color: AppColors.orange500, size: 23),
        ]),
      ),
    );
  }
}
