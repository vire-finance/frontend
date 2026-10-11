import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'google_sign_in_button_stub.dart'
    if (dart.library.js_interop) 'google_sign_in_button_web.dart'
    as renderer;

/// Owns the Web authentication event subscription, while VIRE owns its session.
/// The browser SDK button is rendered only after initialization and subscription.
class GoogleWebSignInButton extends StatefulWidget {
  const GoogleWebSignInButton({
    required this.initialize,
    required this.onCredential,
    required this.onError,
    required this.isRegister,
    required this.enabled,
    @visibleForTesting this.authenticationEvents,
    @visibleForTesting this.buttonBuilder,
    super.key,
  });

  final Future<void> Function() initialize;
  final Future<void> Function(String? idToken) onCredential;
  final void Function(Object error) onError;
  final bool isRegister;
  final bool enabled;

  final Stream<GoogleSignInAuthenticationEvent>? authenticationEvents;
  final Widget Function(bool isRegister)? buttonBuilder;

  @override
  State<GoogleWebSignInButton> createState() => _GoogleWebSignInButtonState();
}

class _GoogleWebSignInButtonState extends State<GoogleWebSignInButton> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;
  Widget? _button;
  bool _initializing = true;
  bool _initializationFailed = false;
  bool _exchangingCredential = false;
  int _initializationGeneration = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Widget _renderButton() =>
      (widget.buttonBuilder ?? renderer.buildGoogleSignInButton)(
        widget.isRegister,
      );

  Future<void> _initialize() async {
    final generation = ++_initializationGeneration;
    try {
      await widget.initialize();
      if (!mounted || generation != _initializationGeneration) return;

      _subscription =
          (widget.authenticationEvents ??
                  GoogleSignIn.instance.authenticationEvents)
              .listen(_onAuthenticationEvent, onError: _onAuthenticationError);
      // Cache the platform view so ordinary form rebuilds do not restart GIS.
      final button = _renderButton();
      setState(() {
        _button = button;
        _initializing = false;
        _initializationFailed = false;
      });
    } catch (error) {
      if (!mounted || generation != _initializationGeneration) return;
      await _subscription?.cancel();
      _subscription = null;
      if (!mounted || generation != _initializationGeneration) return;
      setState(() {
        _initializing = false;
        _initializationFailed = true;
      });
      widget.onError(error);
    }
  }

  void _onAuthenticationEvent(GoogleSignInAuthenticationEvent event) {
    if (!mounted ||
        _initializing ||
        _initializationFailed ||
        !widget.enabled ||
        _exchangingCredential ||
        event is! GoogleSignInAuthenticationEventSignIn) {
      return;
    }
    unawaited(_exchangeCredential(event));
  }

  Future<void> _exchangeCredential(
    GoogleSignInAuthenticationEventSignIn event,
  ) async {
    // Opening or dismissing the Google popup never locks the VIRE form.
    // Only a received credential begins the VIRE backend exchange.
    setState(() => _exchangingCredential = true);
    try {
      await widget.onCredential(event.user.authentication.idToken);
    } catch (error) {
      if (mounted) _onAuthenticationError(error);
    } finally {
      if (mounted) setState(() => _exchangingCredential = false);
    }
  }

  void _onAuthenticationError(Object error) {
    if (!mounted) return;
    if (error is GoogleSignInException &&
        error.code == GoogleSignInExceptionCode.canceled) {
      return;
    }
    widget.onError(error);
  }

  void _retry() {
    if (_initializing || !widget.enabled) return;
    setState(() {
      _initializing = true;
      _initializationFailed = false;
    });
    unawaited(_initialize());
  }

  @override
  void didUpdateWidget(covariant GoogleWebSignInButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRegister != widget.isRegister && _button != null) {
      _button = _renderButton();
    }
  }

  @override
  void dispose() {
    ++_initializationGeneration;
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  Widget _waiting(String label) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.blue500,
        ),
      ),
      const SizedBox(width: 9),
      Text(label, style: AppTextStyles.l3.copyWith(color: AppColors.grey500)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (_initializationFailed) {
      return Column(
        children: [
          Text(
            'Google sign-in is unavailable.',
            style: AppTextStyles.l3.copyWith(color: AppColors.grey500),
          ),
          TextButton(
            onPressed: widget.enabled ? _retry : null,
            child: Text(
              'Try again',
              style: AppTextStyles.l3.copyWith(color: AppColors.blue500),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      // HTML platform views can receive clicks outside Flutter hit testing.
      // Remove the browser button while busy, and guard its event callback too.
      child: _initializing
          ? _waiting('Preparing Google sign-in…')
          : _exchangingCredential || !widget.enabled
          ? _waiting('Please wait…')
          : _button,
    );
  }
}
