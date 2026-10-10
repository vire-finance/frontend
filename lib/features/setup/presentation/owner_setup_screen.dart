import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../dashboard/presentation/owner_dashboard_screen.dart';
import '../../auth/data/auth_repository.dart';
import '../../pin/presentation/pin_screen.dart';
import 'widgets/pair_account_step.dart';
import '../data/fund_sources.dart';

class OwnerSetupScreen extends StatefulWidget {
  const OwnerSetupScreen({super.key});

  @override
  State<OwnerSetupScreen> createState() => _OwnerSetupScreenState();
}

class _OwnerSetupScreenState extends State<OwnerSetupScreen> {
  int _step = 2;
  int _employeeCount = 15;
  String? _selectedSource;

  String? _invitationCode;
  bool _isCreatingWorkspace = false;

  void _back() {
    if (_step == 2) {
      Navigator.of(context).maybePop();
      return;
    }

    setState(() => _step -= 1);
  }

  Future<void> _continue() async {
    if (_step == 2 && _selectedSource == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih sumber dana terlebih dahulu.'),
        ),
      );
      return;
    }

    if (_step == 2) {
      setState(() => _step += 1);
      return;
    }

    if (_step == 3) {
      if (_invitationCode == null && !_isCreatingWorkspace) {
        setState(() => _isCreatingWorkspace = true);
        try {
          _invitationCode = await AuthRepository.instance.setupOwner(
            fundAccountType: FundSources.find(_selectedSource ?? '')?.accountType ?? 'BANK',
            employeesManaged: _employeeCount,
          );
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(apiErrorMessage(error))),
            );
          }
        } finally {
          if (mounted) setState(() => _isCreatingWorkspace = false);
        }
      }
      if (_invitationCode == null || !mounted) return;
      setState(() => _step = 4);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PinScreen(
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
                builder: (_) => const OwnerDashboardScreen(),
              ),
              (route) => false,
            );
          },
        ),
      ),
    );
  }

  Future<void> _copyCode() async {
    final code = _invitationCode;
    if (code == null) return;
    await Clipboard.setData(
      ClipboardData(text: code),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invitation code disalin.'),
      ),
    );
  }

  Future<void> _shareCode() async {
    final code = _invitationCode;
    if (code == null) return;
    await Share.share(
      'Use this Vire invitation code: $code',
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case 2:
        return SetupStepFrame(
          step: 2,
          title: 'Pair Your Main Fund Account',
          description:
              "Link your company's primary bank account to start "
              'managing and funding your business expenses.',
          content: PairAccountStep(
            selectedSource: _selectedSource,
            onSelected: (value) {
              setState(() => _selectedSource = value);
            },
          ),
          onBack: _back,
          onContinue: _continue,
        );

      case 3:
        return SetupStepFrame(
          step: 3,
          title: 'How many employees do you manage?',
          description:
              'Select a rough estimate. This helps us tailor the best '
              'expense management setup for your current business scale.',
          content: _buildEmployeeCount(),
          onBack: _back,
          onContinue: _continue,
        );

      default:
        return SetupStepFrame(
          step: 4,
          title: 'Invitation Code',
          description:
              'Copy or send this code to invite your employees to '
              'your Vire workspace.',
          content: _buildInvitationCode(),
          onBack: _back,
          onContinue: _continue,
          continueLabel: 'Create Pin',
          showArrow: true,
        );
    }
  }

  Widget _buildEmployeeCount() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBubbleLeft =
            (constraints.maxWidth - 42).clamp(0.0, double.infinity).toDouble();
        final bubbleLeft =
            ((_employeeCount / 50) * maxBubbleLeft)
                .clamp(0.0, maxBubbleLeft)
                .toDouble();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1', style: AppTextStyles.l1.semiBold),
                Text('50', style: AppTextStyles.l1.semiBold),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.orange500,
                inactiveTrackColor: AppColors.orange50,
                thumbColor: AppColors.orange500,
                overlayColor:
                    AppColors.orange100.withValues(alpha: 0.35),
                trackHeight: 4,
              ),
              child: Slider(
                min: 1,
                max: 50,
                divisions: 50,
                value: _employeeCount.toDouble(),
                onChanged: (value) {
                  setState(() => _employeeCount = value.round());
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: bubbleLeft),
              child: Container(
                width: 42,
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orange50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_employeeCount',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.l2.bold.copyWith(
                    color: AppColors.orange500,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInvitationCode() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.grey100),
          ),
          child: Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _invitationCode ?? 'Connecting…',
                    maxLines: 1,
                    softWrap: false,
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.orange400,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              _CodeAction(
                icon: Icons.copy_outlined,
                label: 'Copy',
                onTap: _copyCode,
              ),
              const SizedBox(width: 10),
              _CodeAction(
                icon: Icons.send_outlined,
                label: 'Share',
                onTap: _shareCode,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'This code expires after 7 days. Share it with your employees.',
          textAlign: TextAlign.center,
          style: AppTextStyles.l4.copyWith(
            color: AppColors.blue700,
          ),
        ),
      ],
    );
  }
}

class _CodeAction extends StatelessWidget {
  const _CodeAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 3,
          vertical: 5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 21,
              color: AppColors.blue500,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.l4.copyWith(
                color: AppColors.blue500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
