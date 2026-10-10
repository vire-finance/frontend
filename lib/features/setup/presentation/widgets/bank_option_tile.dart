import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class BankOptionTile extends StatelessWidget {
  const BankOptionTile({
    required this.name,
    required this.selected,
    required this.onTap,
    this.logoPath,
    this.icon,
    super.key,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;
  final String? logoPath;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected ? AppColors.blue400 : AppColors.grey100,
              width: selected ? 2 : 1,
            ),
            color: selected ? AppColors.blue50 : AppColors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: logoPath != null
                      ? Image.asset(
                          logoPath!,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        )
                      : Icon(
                          icon ?? Icons.account_balance_wallet_outlined,
                          size: 34,
                          color: AppColors.blue500,
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.l4.semiBold.copyWith(
                  color: AppColors.grey800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}