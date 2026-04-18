#!/bin/bash
set -e

export PATH="$PATH:$HOME/.pub-cache/bin"

echo "Building Flutter web app..."
flutter build web --release

echo "Starting Admin Panel (port 3001)..."
node /home/runner/workspace/admin/server.js &

echo "Serving Flutter web (port 5000)..."
cd build/web && exec dart /home/runner/workspace/serve.dart
