@echo off
REM DocXpress Setup Script for Windows
REM This script helps set up the DocXpress project for development

echo.
echo 🚀 DocXpress Setup Script (Windows)
echo ====================================
echo.

REM Check Flutter installation
echo 📱 Checking Flutter installation...
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter is not installed
    echo Please install Flutter from https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)
echo ✅ Flutter is installed
flutter --version

REM Check Dart installation
echo.
echo 🎯 Checking Dart installation...
dart --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Dart is not installed
    pause
    exit /b 1
)
echo ✅ Dart is installed
dart --version

REM Check Node.js installation
echo.
echo 🟢 Checking Node.js installation...
node --version >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Node.js is not installed
    echo Backend requires Node.js. Install from https://nodejs.org/
) else (
    echo ✅ Node.js is installed
    node --version
)

REM Install Flutter dependencies
echo.
echo 📦 Installing Flutter dependencies...
call flutter pub get
echo ✅ Dependencies installed

REM Create uploads directory
echo.
echo 📁 Creating uploads directory...
if not exist "uploads" mkdir uploads
echo ✅ Uploads directory created

REM Create .env file if it doesn't exist
echo.
echo ⚙️  Checking environment configuration...
if not exist ".env" (
    echo ⚠️  .env file not found
    if exist ".env.example" (
        echo Creating .env from .env.example...
        copy .env.example .env
        echo ✅ .env file created
        echo ⚠️  Please edit .env with your MongoDB URI and other settings
    ) else (
        echo ❌ .env.example not found
    )
) else (
    echo ✅ .env file exists
)

REM Run Flutter analyze
echo.
echo 🔍 Running Flutter analysis...
call flutter analyze --no-fatal-infos
echo ✅ Analysis complete

REM Summary
echo.
echo ====================================
echo ✅ Setup Complete!
echo ====================================
echo.
echo 📋 Next Steps:
echo.
echo 1. 📝 Configure MongoDB:
echo    - Edit .env file with your MongoDB URI
echo    - For local: mongodb://localhost:27017/docxpress
echo    - For Atlas: mongodb+srv://user:pass@cluster.mongodb.net/docxpress
echo.
echo 2. 🔧 Set up Backend:
echo    - cd ..\backend
echo    - npm install
echo    - npm run dev
echo.
echo 3. 🚀 Run Flutter App:
echo    - flutter run -d windows
echo    - or flutter run -d chrome
echo.
echo 4. 📚 Read Documentation:
echo    - README.md - Project overview
echo    - BACKEND_SETUP.md - Backend configuration
echo    - IMPLEMENTATION_STATUS.md - Feature status
echo.
echo 🎉 Happy coding!
echo.
pause
