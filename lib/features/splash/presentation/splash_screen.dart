import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import 'splash_logo.dart';
import '../../auth/data/auth_repository.dart';
import '../../dashboard/presentation/employee_dashboard_screen.dart';
import '../../dashboard/presentation/owner_dashboard_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../pin/presentation/pin_screen.dart';
import '../../setup/presentation/role_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _navigationTimer = Timer(const Duration(milliseconds: 3000), _navigateNext);
  }

  Future<void> _navigateNext() async {
    final role = await AuthRepository.instance.restoreRole();
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final Widget destination = switch (role) {
      'OWNER' => const OwnerDashboardScreen(),
      'EMPLOYEE' => const EmployeeDashboardScreen(),
      'PENDING' => const RoleSelectionScreen(),
      'PIN_OWNER' => _setupPin('OWNER', navigator),
      'PIN_EMPLOYEE' => _setupPin('EMPLOYEE', navigator),
      'OFFLINE' => _OfflineSessionScreen(onRetry: _navigateNext),
      _ => const OnboardingScreen(),
    };
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => destination),
    );
  }

  Widget _setupPin(String role, NavigatorState navigator) => PinScreen(
        onPinSubmitted: AuthRepository.instance.setSecurityPin,
        onSetupComplete: () {
          final Widget dashboard = role == 'OWNER'
              ? const OwnerDashboardScreen()
              : const EmployeeDashboardScreen();
          navigator.pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => dashboard),
              (route) => false);
        },
      );

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.basicWhite,
        body: Center(
            child: SizedBox(
                width: 236, height: 82, child: FittedBox(child: SplashLogo()))),
      ),
    );
  }
}

class _OfflineSessionScreen extends StatelessWidget {
  const _OfflineSessionScreen({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.basicWhite,
        body: SafeArea(
            child: Center(
                child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined,
                size: 58, color: AppColors.blue400),
            const SizedBox(height: 18),
            const Text('Cannot connect to Vire',
                style: TextStyle(
                    color: AppColors.blue900,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
                'Check your connection and try again. Your saved session is still on this device.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey500)),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ]),
        ))),
      );
}
