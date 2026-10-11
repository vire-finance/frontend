# VIRE frontend — build & deploy notes

## API base URL (required for any non-local build)

The base URL is baked in at compile time via
`String.fromEnvironment('VIRE_API_BASE_URL')`
(`lib/core/network/api_client.dart`). There is no runtime config file.
A build without the flag silently targets `http://localhost:8000`
(web/desktop) or `http://10.0.2.2:8000` (Android emulator).

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
