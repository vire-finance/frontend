import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/widgets/app_text_field.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/data/auth_repository.dart';
import '../../dashboard/presentation/employee_dashboard_screen.dart';
import '../../pin/presentation/pin_screen.dart';
import 'widgets/pair_account_step.dart';

class EmployeeSetupScreen extends StatefulWidget {
  const EmployeeSetupScreen({super.key});

  @override
  State<EmployeeSetupScreen> createState() => _EmployeeSetupScreenState();
}

class _EmployeeSetupScreenState extends State<EmployeeSetupScreen> {
  final _invitationController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _invitationController.dispose();
    super.dispose();
  }

  Future<void> _joinCompany() async {
    final code = _invitationController.text.trim();
    if (code.length < 12 || code.length > 64) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Masukkan invitation code yang diberikan owner.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await AuthRepository.instance.setupEmployee(code);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PinScreen(
            successTitle: "You're in!",
            successDescription: 'Your employee account is ready.',
            onPinSubmitted: (pin) async {
              try {
                await AuthRepository.instance.setSecurityPin(pin);
              } catch (error) {
                throw Exception(apiErrorMessage(error));
              }
            },
            onSetupComplete: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                    builder: (_) => const EmployeeDashboardScreen()),
                (route) => false,
              );
            },
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => SetupStepFrame(
        step: 1,
        title: 'Enter your invitation code',
        description:
            "Enter the code from your Business Owner to join your company's workspace.",
        content: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AppInputField(
              controller: _invitationController,
              maxLength: 64,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_-]'))
              ],
              decoration: const AppInputDecoration(
                  hintText: 'Invitation code', counterText: '')),
          const SizedBox(height: 8),
          Text('Invitation codes expire after 7 days.',
              style: AppTextStyles.l4.copyWith(color: AppColors.grey500)),
        ]),
        onBack: () => Navigator.of(context).maybePop(),
        onContinue: _submitting ? () {} : _joinCompany,
        continueLabel: _submitting ? 'Joining…' : 'Join Company',
        showArrow: true,
      );
}
