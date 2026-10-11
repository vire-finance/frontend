import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

/// Google renders the button and opens the account chooser on Web.
Widget buildGoogleSignInButton(bool isRegister) => google_web.renderButton(
  configuration: google_web.GSIButtonConfiguration(
    type: google_web.GSIButtonType.standard,
    theme: google_web.GSIButtonTheme.outline,
    size: google_web.GSIButtonSize.large,
    text: isRegister
        ? google_web.GSIButtonText.signupWith
        : google_web.GSIButtonText.continueWith,
  ),
);
