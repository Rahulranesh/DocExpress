#!/bin/bash

# DocXpress Setup Script
# This script helps set up the DocXpress project for development

set -e

echo "🚀 DocXpress Setup Script"
echo "=========================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Flutter installation
echo "📱 Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed${NC}"
    echo "Please install Flutter from https://flutter.dev/docs/get-started/install"
    exit 1
fi
echo -e "${GREEN}✅ Flutter is installed${NC}"
flutter --version

# Check Dart installation
echo ""
echo "🎯 Checking Dart installation..."
if ! command -v dart &> /dev/null; then
    echo -e "${RED}❌ Dart is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Dart is installed${NC}"
dart --version

# Check Node.js installation (for backend)
echo ""
echo "🟢 Checking Node.js installation..."
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}⚠️  Node.js is not installed${NC}"
    echo "Backend requires Node.js. Install from https://nodejs.org/"
else
    echo -e "${GREEN}✅ Node.js is installed${NC}"
    node --version
fi

# Check MongoDB installation
echo ""
echo "🍃 Checking MongoDB installation..."
if ! command -v mongosh &> /dev/null && ! command -v mongo &> /dev/null; then
    echo -e "${YELLOW}⚠️  MongoDB CLI is not installed${NC}"
    echo "You can use MongoDB Atlas (cloud) instead"
else
    echo -e "${GREEN}✅ MongoDB CLI is installed${NC}"
fi

# Install Flutter dependencies
echo ""
echo "📦 Installing Flutter dependencies..."
flutter pub get
echo -e "${GREEN}✅ Dependencies installed${NC}"

# Create uploads directory for backend
echo ""
echo "📁 Creating uploads directory..."
mkdir -p uploads
echo -e "${GREEN}✅ Uploads directory created${NC}"

# Create .env file if it doesn't exist
echo ""
echo "⚙️  Checking environment configuration..."
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env file not found${NC}"
    echo "Creating .env from .env.example..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${GREEN}✅ .env file created${NC}"
        echo -e "${YELLOW}⚠️  Please edit .env with your MongoDB URI and other settings${NC}"
    else
        echo -e "${RED}❌ .env.example not found${NC}"
    fi
else
    echo -e "${GREEN}✅ .env file exists${NC}"
fi

# Run Flutter analyze
echo ""
echo "🔍 Running Flutter analysis..."
flutter analyze --no-fatal-infos || true
echo -e "${GREEN}✅ Analysis complete${NC}"

# Summary
echo ""
echo "=========================="
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo "=========================="
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. 📝 Configure MongoDB:"
echo "   - Edit .env file with your MongoDB URI"
echo "   - For local: mongodb://localhost:27017/docxpress"
echo "   - For Atlas: mongodb+srv://user:pass@cluster.mongodb.net/docxpress"
echo ""
echo "2. 🔧 Set up Backend:"
echo "   - cd ../backend"
echo "   - npm install"
echo "   - npm run dev"
echo ""
echo "3. 🚀 Run Flutter App:"
echo "   - flutter run -d linux"
echo "   - or flutter run -d chrome"
echo ""
echo "4. 📚 Read Documentation:"
echo "   - README.md - Project overview"
echo "   - BACKEND_SETUP.md - Backend configuration"
echo "   - IMPLEMENTATION_STATUS.md - Feature status"
echo ""
echo "🎉 Happy coding!"
