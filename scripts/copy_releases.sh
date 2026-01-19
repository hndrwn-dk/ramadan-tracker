#!/bin/bash

# Script to copy release builds to releases folder with versioning
# Usage: ./scripts/copy_releases.sh

cd "$(dirname "$0")/.."

# Get version from pubspec.yaml
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')

if [ -z "$VERSION" ]; then
    echo "Error: Could not find version in pubspec.yaml"
    exit 1
fi

echo "Version: $VERSION"

# Create releases folder if it doesn't exist
mkdir -p releases

# Copy APK
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    cp build/app/outputs/flutter-apk/app-release.apk "releases/ramadan-tracker-v${VERSION}.apk"
    echo "✓ Copied APK: releases/ramadan-tracker-v${VERSION}.apk"
else
    echo "✗ APK not found: build/app/outputs/flutter-apk/app-release.apk"
fi

# Copy AAB
if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    cp build/app/outputs/bundle/release/app-release.aab "releases/ramadan-tracker-v${VERSION}.aab"
    echo "✓ Copied AAB: releases/ramadan-tracker-v${VERSION}.aab"
else
    echo "✗ AAB not found: build/app/outputs/bundle/release/app-release.aab"
fi

echo ""
echo "Release files copied to releases/ folder"
ls -lh releases/ | grep "ramadan-tracker-v${VERSION}"

