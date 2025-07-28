#!/bin/bash
set -e

echo "🚀 Starting Flutter web build..."

# Install Flutter
echo "📥 Installing Flutter..."
wget -qO- https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz | tar -xJf -
export PATH="$PATH:$(pwd)/flutter/bin"

# Verify Flutter
echo "🔍 Verifying Flutter..."
flutter --version

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build web app
echo "🏗️ Building web app..."
flutter build web --release

echo "✅ Build completed!"
