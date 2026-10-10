import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AppNavigationItem {
  const AppNavigationItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
}

const vireNavigationItems = [
  AppNavigationItem(label: 'Home', icon: Icons.home_outlined),
  AppNavigationItem(
    label: 'Pocket',
    icon: Icons.account_balance_wallet_outlined,
  ),
  AppNavigationItem(label: 'Document', icon: Icons.receipt_long_outlined),
  AppNavigationItem(label: 'History', icon: Icons.history),
  AppNavigationItem(label: 'Profile', icon: Icons.person_outline),
];

const employeeNavigationItems = [
  AppNavigationItem(label: 'Home', icon: Icons.home_outlined),
  AppNavigationItem(
    label: 'Pocket',
    icon: Icons.account_balance_wallet_outlined,
  ),
  AppNavigationItem(label: 'Request', icon: Icons.receipt_long_outlined),
  AppNavigationItem(label: 'History', icon: Icons.history),
  AppNavigationItem(
    label: 'Profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];

class AppNavbar extends StatelessWidget {
  const AppNavbar({
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final List<AppNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.blue50,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = selectedIndex == index;
              final color = selected ? AppColors.blue500 : AppColors.blue400;

              return Expanded(
                child: InkWell(
                  onTap: () => onDestinationSelected(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? item.selectedIcon ?? item.icon : item.icon,
                        size: 21,
                        color: color,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: AppTextStyles.l4.copyWith(
                          color: color,
                          fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
