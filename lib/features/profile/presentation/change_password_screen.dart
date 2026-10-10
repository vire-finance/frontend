import '../../../shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  final _hidden = [true, true, true];
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await AuthRepository.instance.changePassword(
          currentPassword: _current.text,
          newPassword: _next.text,
          confirmPassword: _confirm.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password updated. Please sign in again.')));
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
          (route) => false);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String label, TextEditingController controller, int index,
          String? Function(String?) validator) =>
      AppFormField(controller: controller, enabled: !_saving, obscureText: _hidden[index], autocorrect: false, enableSuggestions: false, maxLength: 128, validator: validator, textInputAction:
            index == 2 ? TextInputAction.done : TextInputAction.next, onFieldSubmitted: index == 2 ? (_) => _save() : null, decoration: AppInputDecoration(labelText: label, counterText: '', suffixIcon: IconButton(
              tooltip: _hidden[index] ? 'Show password' : 'Hide password',
              onPressed: _saving
                  ? null
                  : () => setState(() => _hidden[index] = !_hidden[index]),
              icon: Icon(_hidden[index]
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined))));

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.basicWhite,
        appBar: AppBar(
            title: const Text('Change Password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            centerTitle: true,
            backgroundColor: AppColors.basicWhite,
            foregroundColor: AppColors.blue900),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                        'Use at least 10 characters, including uppercase, lowercase, and a number.',
                        style:
                            TextStyle(color: AppColors.grey500, fontSize: 13)),
                    const SizedBox(height: 24),
                    _field(
                        'Current Password',
                        _current,
                        0,
                        (value) => value == null || value.isEmpty
                            ? 'Enter your current password'
                            : null),
                    const SizedBox(height: 18),
                    _field('New Password', _next, 1, (value) {
                      if (value == null || value.length < 10) {
                        return 'Use at least 10 characters';
                      }
                      if (!RegExp(r'[a-z]').hasMatch(value) ||
                          !RegExp(r'[A-Z]').hasMatch(value) ||
                          !RegExp(r'[0-9]').hasMatch(value)) {
                        return 'Include uppercase, lowercase, and a number';
                      }
                      if (value == _current.text) {
                        return 'Choose a different password';
                      }
                      return null;
                    }),
                    const SizedBox(height: 18),
                    _field(
                        'Confirm New Password',
                        _confirm,
                        2,
                        (value) => value == null || value.isEmpty
                            ? 'Confirm your new password'
                            : value != _next.text
                                ? 'Passwords do not match'
                                : null),
                    const SizedBox(height: 24),
                    const Text(
                        'After saving, you will be signed out of all devices. Sign in again with your new password.',
                        style:
                            TextStyle(color: AppColors.grey500, fontSize: 13)),
                    const SizedBox(height: 18),
                    SizedBox(
                        height: 48,
                        child: FilledButton(
                            onPressed: _saving ? null : _save,
                            child:
                                Text(_saving ? 'Saving…' : 'Save Password'))),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
