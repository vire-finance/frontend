import 'package:flutter/widgets.dart';

/// Keeps Web SDK imports out of Android and native widget test builds.
Widget buildGoogleSignInButton(bool isRegister) => const SizedBox.shrink();
