import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'employee_setup_screen.dart';
import 'owner_setup_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  void _continue() {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih role terlebih dahulu.')),
      );
      return;
    }

    final screen = _selectedRole == 'Business Owner'
        ? const OwnerSetupScreen()
        : const EmployeeSetupScreen();

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 760;
          final panelTop = compact ? constraints.maxHeight * 0.24 : 235.0;
          final pageWidth =
              constraints.maxWidth > 430 ? 430.0 : constraints.maxWidth;

          return Center(
            child: SizedBox(
              width: pageWidth,
              height: constraints.maxHeight,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: panelTop + 19,
                    child: Image.asset(
                      'assets/images/Regular Images/Soft Pattern Background.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  Positioned(
                    top: panelTop * 0.45,
                    left: 0,
                    right: 0,
                    height: compact ? 58 : 76,
                    child: Image.asset(
                      'assets/images/Regular Images/Logo - VIRE.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned.fill(
                    top: panelTop,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            compact ? 12 : 18,
                            20,
                            compact ? 12 : 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Step 1 of 4',
                                  style: AppTextStyles.l3.semiBold.copyWith(
                                    color: AppColors.grey500,
                                  ),
                                ),
                              ),
                              SizedBox(height: compact ? 4 : 7),
                              Text(
                                'Who Are You?',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.h3.bold.copyWith(
                                  color: AppColors.blue400,
                                ),
                              ),
                              SizedBox(height: compact ? 8 : 14),
                              Text(
                                'Choose the role that best describes your position',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.p2.copyWith(
                                  color: AppColors.grey800,
                                ),
                              ),
                              SizedBox(height: compact ? 12 : 28),
                              _RoleCard(
                                title: 'Business Owner',
                                imagePath:
                                    'assets/images/Regular Images/Choice - Business Owner.png',
                                selected: _selectedRole == 'Business Owner',
                                titleColor: AppColors.blue500,
                                imageOnLeft: true,
                                height: compact ? 96 : 146,
                                onTap: () => setState(
                                  () => _selectedRole = 'Business Owner',
                                ),
                              ),
                              SizedBox(height: compact ? 8 : 10),
                              _RoleCard(
                                title: 'Employee',
                                imagePath:
                                    'assets/images/Regular Images/Choice - Employee.png',
                                selected: _selectedRole == 'Employee',
                                titleColor: AppColors.orange400,
                                imageOnLeft: false,
                                height: compact ? 96 : 146,
                                onTap: () => setState(
                                  () => _selectedRole = 'Employee',
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 46,
                                      child: TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).maybePop(),
                                        style: TextButton.styleFrom(
                                          backgroundColor: AppColors.blue50,
                                          foregroundColor: AppColors.blue500,
                                        ),
                                        child: Text(
                                          'Back',
                                          style: AppTextStyles.l2.semiBold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SizedBox(
                                      height: 46,
                                      child: ElevatedButton(
                                        onPressed: _continue,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.blue400,
                                          foregroundColor: AppColors.white,
                                          elevation: 0,
                                        ),
                                        child: Text(
                                          'Continue',
                                          style: AppTextStyles.l2.semiBold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.imagePath,
    required this.selected,
    required this.titleColor,
    required this.imageOnLeft,
    required this.height,
    required this.onTap,
  });

  final String title;
  final String imagePath;
  final bool selected;
  final Color titleColor;
  final bool imageOnLeft;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageWidth = height * 1.45;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.blue400 : AppColors.grey100,
              width: selected ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Stack(
              children: [
                Positioned(
                  left: imageOnLeft ? 0 : null,
                  right: imageOnLeft ? null : 0,
                  top: 0,
                  bottom: 0,
                  width: imageWidth,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    alignment: imageOnLeft
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Align(
                      alignment: imageOnLeft
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Text(
                        title,
                        style: AppTextStyles.h5.bold.copyWith(
                          color: titleColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}