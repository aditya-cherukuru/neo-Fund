#!/bin/bash

# Flutter Web Development Script
# This script builds the web app and serves it locally for persistent session testing

echo "🚀 Starting MintMate Web Development Server..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 is not installed or not in PATH"
    exit 1
fi

# Clean previous build
echo "🧹 Cleaning previous build..."
flutter clean

# Build web app
echo "🔨 Building Flutter web app..."
flutter build web --release

# Check if build was successful
if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build completed successfully!"

# Navigate to build directory
cd build/web

# Check if port 8080 is available
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  Port 8080 is already in use. Trying port 8081..."
    PORT=8081
else
    PORT=8080
fi

echo "🌐 Starting local server on port $PORT..."
echo "📱 Open your browser and navigate to: http://localhost:$PORT"
echo "💡 Use your default Chrome browser (not the Flutter dev server) for persistent sessions!"
echo ""
echo "Press Ctrl+C to stop the server"

# Start Python HTTP server
python3 -m http.server $PORT 