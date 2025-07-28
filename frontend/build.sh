#!/bin/bash

# Exit on any error
set -e

echo "🚀 Starting Flutter web build for Netlify..."

# Configure git to avoid commit date issues
git config --global user.email "build@netlify.com"
git config --global user.name "Netlify Build"

# Install Flutter if not already installed
if ! command -v flutter &> /dev/null; then
    echo "📥 Installing Flutter..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
    export PATH="$PATH:$(pwd)/flutter/bin"
fi

# Verify Flutter installation
echo "🔍 Verifying Flutter installation..."
flutter --version

# Get Flutter dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Build the web app with specific flags to avoid git issues
echo "🏗️ Building Flutter web app..."
flutter build web --release --dart-define=FLUTTER_WEB_USE_SKIA=true

echo "✅ Build completed successfully!"
echo "📁 Build output is in: build/web/" 