# VIRE frontend — build & deploy notes

## API base URL

The base URL is baked in at compile time via
`String.fromEnvironment('VIRE_API_BASE_URL')`
(`lib/core/network/api_client.dart`). There is no runtime config file.
Debug builds without the flag target the local backend. Release builds without the flag target the Render backend below;
set VIRE_API_BASE_URL explicitly to override either default.

```powershell
# Local backend
flutter run --dart-define VIRE_API_BASE_URL=http://localhost:8000 `
  --dart-define-from-file=firebase-config.json

# Production web against Render (MANUAL: verify the URL first)
flutter build web --release `
  --dart-define VIRE_API_BASE_URL=https://vire-backend-1e3o.onrender.com `
  --dart-define-from-file=firebase-config.json
```

The backend must list the deployed web origin in its `CORS_ORIGINS`
Render variable, or authenticated web calls fail preflight.


## Render website deployment

The Render Blueprint in `render.yaml` publishes a landing page at `/`, the Flutter app at `/app.html`, and the Android installer at `/downloads/vire.apk`. The build script pins Flutter 3.47.6 and builds the web app with the Render backend URL as its release default.

Before first publish, add the website origin to the backend Render service's `CORS_ORIGINS` and to the Google OAuth Web client as an Authorized JavaScript origin. For Android Google sign-in, the Android OAuth client must match package `com.example.vire` and the signing certificate SHA-1; the Android and Web OAuth clients must be in the same Google Cloud project.
## Firebase config

Copy `firebase-config.example.json` to `firebase-config.json` and fill in
the Firebase console values, or pass the four keys as individual
`--dart-define` flags. `firebase-config.json` currently contains a client
API key and is tracked for local development convenience: client keys are
public by design, but restrict them in the Firebase console (Android/iOS/
HTTP referrers) and never put private credentials in this file. Private
server credentials (`*service-account*.json`, `*firebase-admin*.json`)
are git-ignored and must stay backend-only.

## Auth/session notes

- Tokens live in `FlutterSecureStorage` (`vire.access_token`,
  `vire.refresh_token`, `vire.role`). Refresh uses 10s timeouts and never
  persists a partial rotation (both tokens required).
- Biometric authentication is not implemented: the PIN pad renders an
  empty fingerprint slot. Do not advertise biometric login.
