import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum AppToastType { warning, info, error, success }

abstract final class AppToast {
  static void show(BuildContext context, String message,
      {AppToastType type = AppToastType.info}) {
    final (color, icon) = switch (type) {
      AppToastType.warning => (AppColors.orange700, Icons.warning_amber_rounded),
      AppToastType.info => (AppColors.blue700, Icons.info_outline),
      AppToastType.error => (AppColors.red600, Icons.error_outline),
      AppToastType.success => (AppColors.green700, Icons.check_circle_outline),
    };
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 3),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(children: [
          Icon(icon, size: 19, color: AppColors.white),
          const SizedBox(width: 10),
          Expanded(child: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis)),
        ]),
      ));
  }
}
