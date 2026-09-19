#!/usr/bin/env bash
# Build the Flutter web app against Firebase and deploy to Firebase Hosting.
# Usage:  ./deploy-web.sh
set -euo pipefail

# Flutter + a Node the Firebase CLI can run on (your system Node 26 breaks it).
export PATH="$HOME/flutter-sdk/bin:$PATH"
if [ -d "/opt/homebrew/opt/node@20/bin" ]; then
  export PATH="/opt/homebrew/opt/node@20/bin:$PATH"
fi

echo "==> Node: $(node --version)   Firebase: $(firebase --version)"

echo "==> Building web (Firebase backend)…"
flutter build web --dart-define=BACKEND=firebase

echo "==> Deploying to Firebase Hosting…"
firebase deploy --only hosting

echo ""
echo "Done. Your shareable link:  https://canteen-app-72a86.web.app"
