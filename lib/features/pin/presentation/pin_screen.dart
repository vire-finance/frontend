import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/presentation/widgets/account_created_modal.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({
    this.title = 'Create your security PIN',
    this.successTitle = 'Setup complete!',
    this.successDescription =
        "Your workspace is all set. You're ready to explore your dashboard now.",
    this.onSetupComplete,
    this.onPinComplete,
    this.onPinSubmitted,
    this.showSuccessModal = true,
    this.showFingerprintButton = false,
    super.key,
  });

  final String title;
  final String successTitle;
  final String successDescription;
  final VoidCallback? onSetupComplete;
  final VoidCallback? onPinComplete;
  final Future<void> Function(String pin)? onPinSubmitted;
  final bool showSuccessModal;
  final bool showFingerprintButton;

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  bool _showingSuccess = false;
  Timer? _successTimer;

  @override
  void dispose() {
    _successTimer?.cancel();
    super.dispose();
  }

  void _addDigit(String digit) {
    if (_pin.length >= 4 || _showingSuccess) return;

    setState(() {
      _pin += digit;
      if (_pin.length == 4) {
        _showingSuccess = true;
      }
    });

    if (_pin.length == 4) {
      _successTimer = Timer(
        const Duration(milliseconds: 250),
        _showSuccess,
      );
    }
  }

  void _deleteDigit() {
    if (_pin.isEmpty || _showingSuccess) return;

    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _showSuccess() async {
    if (!mounted) return;

    try {
      await widget.onPinSubmitted?.call(_pin);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
      setState(() {
        _pin = '';
        _showingSuccess = false;
      });
      return;
    }

    if (!mounted) return;

    if (!widget.showSuccessModal) {
      widget.onPinComplete?.call();
      return;
    }

    await SetupCompleteModal.show(
      context,
      title: widget.successTitle,
      description: widget.successDescription,
      onContinue: () {
        final onSetupComplete = widget.onSetupComplete;
        if (onSetupComplete != null) {
          onSetupComplete();
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
    );

    if (!mounted) return;

    setState(() {
      _pin = '';
      _showingSuccess = false;
    });
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < _pin.length;

        return Container(
          width: 25,
          height: 25,
          margin: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppColors.blue400 : Colors.transparent,
            border: Border.all(
              color: isFilled ? AppColors.blue400 : AppColors.grey200,
              width: 1.2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKey(String value) {
    final isBackspace = value == '⌫';

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: isBackspace ? _deleteDigit : () => _addDigit(value),
        borderRadius: BorderRadius.circular(20),
        child: Center(
          child: isBackspace
              ? const Icon(
                  Icons.backspace_outlined,
                  size: 34,
                  color: AppColors.grey700,
                )
              : Text(
                  value,
                  style: AppTextStyles.h2.semiBold.copyWith(
                    color: AppColors.grey700,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.basicWhite,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pageWidth =
                constraints.maxWidth > 430 ? 430.0 : constraints.maxWidth;

            return Center(
              child: SizedBox(
                width: pageWidth,
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      child: SizedBox(
                        height: 42,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                                icon: const Icon(Icons.chevron_left),
                              ),
                            ),
                            Text(
                              'Payment',
                              style: AppTextStyles.l2.bold.copyWith(
                                color: AppColors.blue900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 42),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h3.bold.copyWith(
                        color: AppColors.blue500,
                      ),
                    ),
                    const SizedBox(height: 52),
                    _buildPinDots(),
                    const SizedBox(height: 48),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: AppColors.blue50,
                        padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
                        child: GridView.count(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.08,
                          children: [
                              for (final key in const [
                                '1', '2', '3',
                                '4', '5', '6',
                                '7', '8', '9',
                                'fingerprint', '0', '⌫',
                              ])
                                key == 'fingerprint' && !widget.showFingerprintButton
                                    ? const SizedBox.shrink()
                                    : key == 'fingerprint'
                                        ? _buildFingerprintKey()
                                        : _buildKey(key),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFingerprintKey() => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric verification is not connected yet.')),
          ),
          borderRadius: BorderRadius.circular(20),
          child: const Center(child: Icon(Icons.fingerprint, size: 38, color: AppColors.grey700)),
        ),
      );
}
