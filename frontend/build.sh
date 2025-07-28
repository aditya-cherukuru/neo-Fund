#!/bin/bash

# Exit on any error and enable debugging
set -e
set -x

echo "🚀 Starting Flutter web build for Netlify..."

# Print environment info
echo "📋 Environment Info:"
echo "  - PWD: $(pwd)"
echo "  - PATH: $PATH"
echo "  - FLUTTER_VERSION: $FLUTTER_VERSION"
echo "  - NODE_VERSION: $NODE_VERSION"

# Check if Flutter is already installed
if command -v flutter &> /dev/null; then
    echo "✅ Flutter is already installed"
    flutter --version
else
    echo "📥 Installing Flutter..."
    
    # Create a temporary directory for Flutter
    mkdir -p /tmp/flutter
    cd /tmp/flutter
    
    # Download Flutter
    echo "📥 Downloading Flutter..."
    curl -sSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz -o flutter.tar.xz
    
    # Extract Flutter
    echo "📦 Extracting Flutter..."
    tar xf flutter.tar.xz
    
    # Add Flutter to PATH
    export PATH="$PATH:/tmp/flutter/flutter/bin"
    
    # Go back to project directory
    cd -
fi

# Verify Flutter installation
echo "🔍 Verifying Flutter installation..."
flutter --version

# Check if we're in the right directory
echo "📁 Current directory: $(pwd)"
echo "📁 Directory contents:"
ls -la

# Get Flutter dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Clean any previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies again after clean
echo "📦 Getting Flutter dependencies after clean..."
flutter pub get

# Build the web app
echo "🏗️ Building Flutter web app..."
flutter build web --release

# Verify build output
echo "✅ Verifying build output..."
if [ -d "build/web" ]; then
    echo "📁 Build output directory exists"
    echo "📁 Build output contents:"
    ls -la build/web/
    
    # Check for essential files
    if [ -f "build/web/index.html" ]; then
        echo "✅ index.html exists"
    else
        echo "❌ index.html missing"
        exit 1
    fi
    
    if [ -f "build/web/main.dart.js" ]; then
        echo "✅ main.dart.js exists"
    else
        echo "❌ main.dart.js missing"
        exit 1
    fi
else
    echo "❌ Build output directory missing"
    exit 1
fi

echo "🎉 Build completed successfully!"
echo "📁 Build output is in: build/web/" 