@echo off
REM Flutter Web Development Script for Windows
REM This script builds the web app and serves it locally for persistent session testing

echo 🚀 Starting MintMate Web Development Server...

REM Check if Flutter is installed
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter is not installed or not in PATH
    pause
    exit /b 1
)

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python is not installed or not in PATH
    pause
    exit /b 1
)

REM Clean previous build
echo 🧹 Cleaning previous build...
flutter clean

REM Build web app
echo 🔨 Building Flutter web app...
flutter build web --release

REM Check if build was successful
if errorlevel 1 (
    echo ❌ Build failed!
    pause
    exit /b 1
)

echo ✅ Build completed successfully!

REM Navigate to build directory
cd build\web

REM Check if port 8080 is available
netstat -an | find "8080" >nul 2>&1
if errorlevel 1 (
    set PORT=8080
) else (
    echo ⚠️  Port 8080 is already in use. Trying port 8081...
    set PORT=8081
)

echo 🌐 Starting local server on port %PORT%...
echo 📱 Open your browser and navigate to: http://localhost:%PORT%
echo 💡 Use your default Chrome browser (not the Flutter dev server) for persistent sessions!
echo.
echo Press Ctrl+C to stop the server

REM Start Python HTTP server
python -m http.server %PORT% 