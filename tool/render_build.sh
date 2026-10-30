#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="3.47.6"
FLUTTER_ROOT="${FLUTTER_ROOT:-$HOME/.cache/flutter-3.47.6}"

if [[ ! -x "$FLUTTER_ROOT/bin/flutter" ]]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_ROOT"
fi

"$FLUTTER_ROOT/bin/flutter" config --no-analytics
"$FLUTTER_ROOT/bin/flutter" pub get
"$FLUTTER_ROOT/bin/flutter" build web --release --dart-define-from-file=firebase-config.json

cp build/web/index.html build/web/app.html
cp web/landing.html build/web/index.html
mkdir -p build/web/downloads
cp web/downloads/vire.apk build/web/downloads/vire.apk