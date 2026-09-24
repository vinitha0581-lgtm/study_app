#!/bin/bash
set -e

echo "=========================================="
echo "📱 Building StudyFlow Android APK"
echo "=========================================="

if ! command -v flutter &> /dev/null; then
    echo "⚠️ Flutter SDK not found in PATH."
    echo "Please ensure Flutter is installed, or use GitHub Actions / PWA install."
    exit 1
fi

echo "📦 Fetching Flutter dependencies..."
flutter pub get

echo "🔨 Compiling Release APK..."
flutter build apk --release

echo ""
echo "=========================================="
echo "✅ APK Built Successfully!"
echo "📍 APK Location: build/app/outputs/flutter-apk/app-release.apk"
echo "=========================================="
