import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/services/push_notification_service.dart';
import 'features/splash/presentation/splash_screen.dart';

class VireApp extends StatelessWidget {
  const VireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Vire',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
