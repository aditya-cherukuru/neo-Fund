#!/bin/bash
set -e

echo "🚀 Starting Flutter web build using Netlify environment..."

# Check Flutter version provided by Netlify
flutter --version

# Get dependencies
echo "📦 Running flutter pub get..."
flutter pub get

# Build web
echo "🏗️ Building Flutter web app..."
flutter build web --release

echo "✅ Flutter web build completed successfully!"
