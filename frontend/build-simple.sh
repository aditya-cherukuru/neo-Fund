#!/bin/bash

# Exit on any error
set -e

echo "🚀 Starting Flutter web build for Netlify (Simple Mode)..."

# Disable git operations that might cause issues
export FLUTTER_GIT_URL="https://github.com/flutter/flutter.git"
export SKIP_GIT_OPERATIONS="true"

# Install Flutter using a more direct approach
if ! command -v flutter &> /dev/null; then
    echo "📥 Installing Flutter..."
    # Use a direct download approach instead of git clone
    wget -qO- https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz | tar xJ
    export PATH="$PATH:$(pwd)/flutter/bin"
fi

# Verify Flutter installation
echo "🔍 Verifying Flutter installation..."
flutter --version

# Get Flutter dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Build the web app with minimal git interaction
echo "🏗️ Building Flutter web app..."
flutter build web --release --no-tree-shake-icons

echo "✅ Build completed successfully!"
echo "📁 Build output is in: build/web/" 