#!/usr/bin/env bash
set -euo pipefail

flutter pub get
flutter build web --release --base-href "/frontend/" --dart-define-from-file=firebase-config.json

cp build/web/index.html build/web/app.html
cp web/landing.html build/web/index.html
mkdir -p build/web/downloads
cp web/downloads/vire.apk build/web/downloads/vire.apk
touch build/web/.nojekyll