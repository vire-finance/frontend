import '../../../shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../core/network/api_client.dart';
import '../../dashboard/presentation/employee_dashboard_screen.dart';
import '../../dashboard/presentation/owner_dashboard_screen.dart';
import '../data/auth_repository.dart';
import 'package:flutter/services.dart';
import '../../setup/presentation/role_selection_screen.dart';
import 'widgets/account_created_modal.dart';
import 'widgets/google_web_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    this.initiallyRegister = false,
    super.key,
  });

  final bool initiallyRegister;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isRegister = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initiallyRegister;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    AppToast.show(context, message, type: AppToastType.error);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      if (_isRegister) {
        await AuthRepository.instance.register(
          email: _emailController.text,
          username: _usernameController.text,
          phoneNumber: _phoneController.text,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );
        if (!mounted) return;
        await AccountCreatedModal.show(
          context,
          onContinue: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
                builder: (_) => const RoleSelectionScreen()),
          ),
        );
      } else {
        final response = await AuthRepository.instance.login(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (!mounted) return;
        final role = response['role'] as String?;
        final Widget destination = role == 'OWNER'
            ? const OwnerDashboardScreen()
            : const EmployeeDashboardScreen();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => destination),
          (route) => false,
        );
      }
    } catch (error) {
      if (mounted) _showMessage(apiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bagian ini wajib diisi';
    }
    return null;
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: AppTextStyles.l3.copyWith(
                  color: AppColors.blue500,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                '*',
                style: AppTextStyles.l3.semiBold.copyWith(
                  color: AppColors.red500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          AppFormField(
              controller: controller,
              validator: validator ?? _required,
              keyboardType: keyboardType,
              obscureText: obscureText,
              decoration: AppInputDecoration(
                  hintText: hint,
                  suffixIcon: onToggleVisibility == null
                      ? null
                      : IconButton(
                          onPressed: onToggleVisibility,
                          icon: Icon(
                            obscureText
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 19,
                            color: AppColors.blue500,
                          ),
                        ))),
        ],
      ),
    );
  }

  Widget _authTabs() {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.grey50),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _tabButton('Login', selected: !_isRegister, onTap: () {
            setState(() => _isRegister = false);
          }),
          _tabButton('Register', selected: _isRegister, onTap: () {
            setState(() => _isRegister = true);
          }),
        ],
      ),
    );
  }

  Widget _tabButton(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: selected ? AppColors.blue400 : AppColors.white,
          foregroundColor: selected ? AppColors.white : AppColors.grey300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: Text(label, style: AppTextStyles.l2.semiBold),
      ),
    );
  }

  Widget _primaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue400,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _isSubmitting ? 'Please wait…' : (_isRegister ? 'Register' : 'Login'),
          style: AppTextStyles.l2.semiBold.copyWith(
            color: AppColors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _submitGoogle() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final response = await AuthRepository.instance.loginWithGoogle();
      if (!mounted) return;
      if (response == null) {
        _showMessage(
            'Google sign-in did not complete. Check Android OAuth setup and try again.');
        return;
      }
      _navigateAfterGoogle(response);
    } catch (error) {
      if (mounted) _showMessage(apiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitGoogleIdToken(String? token) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final response =
          await AuthRepository.instance.loginWithGoogleIdToken(token);
      if (mounted) _navigateAfterGoogle(response);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _navigateAfterGoogle(Map<String, dynamic> response) {
    final role = response['role'] as String?;
    final Widget destination = role == 'OWNER'
        ? const OwnerDashboardScreen()
        : role == 'EMPLOYEE'
            ? const EmployeeDashboardScreen()
            : const RoleSelectionScreen();
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => destination), (route) => false);
  }

  Widget _googleButton() {
    if (kIsWeb) {
      return GoogleWebSignInButton(
        initialize: AuthRepository.instance.initializeGoogle,
        onCredential: _submitGoogleIdToken,
        onError: (error) {
          if (mounted) _showMessage(apiErrorMessage(error));
        },
        isRegister: _isRegister,
        enabled: !_isSubmitting,
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: _isSubmitting ? null : _submitGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.blue50,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isRegister ? 'Register with Google' : 'Login with Google',
              style: AppTextStyles.l2.semiBold.copyWith(
                color: AppColors.blue500,
              ),
            ),
            const SizedBox(width: 9),
            Text(
              'G',
              style: AppTextStyles.h6.bold.copyWith(
                color: AppColors.blue500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final panelTop = _isRegister ? 68.0 : 245.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.basicWhite,
        body: Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(color: AppColors.basicWhite),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: panelTop + 12,
              child: Image.asset(
                'assets/images/Regular Images/Soft Pattern Background.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            if (!_isRegister)
              Positioned(
                top: 105,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 78,
                  child: Image.asset(
                    'assets/images/Regular Images/Logo - VIRE.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            Positioned(
              top: panelTop,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.basicWhite,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _authTabs(),
                          const SizedBox(height: 27),
                          Center(
                            child: Text(
                              _isRegister ? "Let's Join Us!" : 'Welcome Back!',
                              style: AppTextStyles.h4.semiBold.copyWith(
                                color: AppColors.blue900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_isRegister) ...[
                            _field(
                              label: 'Email',
                              hint: 'Type your email here..',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                final requiredError = _required(value);
                                if (requiredError != null) return requiredError;
                                if (!value!.contains('@')) {
                                  return 'Masukkan email yang valid';
                                }
                                return null;
                              },
                            ),
                            _field(
                              label: 'Username',
                              hint: 'Type your username here..',
                              controller: _usernameController,
                            ),
                            _field(
                              label: 'Phone Number',
                              hint: 'Type your phone number here..',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                            ),
                          ] else
                            _field(
                              label: 'Email',
                              hint: 'Type your email here..',
                              controller: _emailController,
                            ),
                          _field(
                            label: 'Password',
                            hint: 'Type your password here..',
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            onToggleVisibility: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            validator: (value) {
                              final requiredError = _required(value);
                              if (requiredError != null) return requiredError;
                              if (_isRegister && value!.length < 10) {
                                return 'Password minimal 10 karakter';
                              }
                              if (_isRegister &&
                                  (!RegExp(r'[a-z]').hasMatch(value!) ||
                                      !RegExp(r'[A-Z]').hasMatch(value) ||
                                      !RegExp(r'[0-9]').hasMatch(value))) {
                                return 'Gunakan huruf besar, huruf kecil, dan angka';
                              }
                              return null;
                            },
                          ),
                          if (_isRegister)
                            _field(
                              label: 'Confirm Password',
                              hint: 'Type your password here..',
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              onToggleVisibility: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              validator: (value) {
                                final requiredError = _required(value);
                                if (requiredError != null) return requiredError;
                                if (value != _passwordController.text) {
                                  return 'Password tidak sama';
                                }
                                return null;
                              },
                            ),
                          if (!_isRegister)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _showMessage(
                                  'Pemulihan password belum disambungkan.',
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 28),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Forgot Password?',
                                  style: AppTextStyles.l3.copyWith(
                                    color: AppColors.blue500,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          SizedBox(height: _isRegister ? 22 : 34),
                          _primaryButton(),
                          const SizedBox(height: 10),
                          _googleButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
