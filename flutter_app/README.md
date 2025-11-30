# DocXpress - All-in-One Document Processing App

A powerful Flutter application for document scanning, conversion, compression, and note-taking. Process PDFs, images, videos, and documents with ease.

## 🌟 Features

### Document Compression
- **Image Compression**: Reduce image file sizes with quality control
- **PDF Compression**: Compress PDF files while maintaining quality
- **Video Compression**: Compress video files with preset options

### Document Conversion
- **Images to PDF**: Convert multiple images to PDF
- **Images to PPTX**: Create presentations from images
- **Images to DOCX**: Generate documents from images
- **PDF to PPTX**: Convert PDFs to presentations
- **PDF to DOCX**: Convert PDFs to documents
- **DOCX to PDF**: Convert documents to PDF
- **PPTX to PDF**: Convert presentations to PDF
- **Image Format Conversion**: Convert between PNG, JPG, WebP, TIFF, GIF

### PDF Operations
- **Merge PDFs**: Combine multiple PDFs into one
- **Split PDFs**: Split PDFs by page ranges
- **Reorder Pages**: Rearrange PDF pages
- **Add Watermark**: Add text watermarks to PDFs
- **Remove Pages**: Delete specific pages from PDFs
- **Rotate Pages**: Rotate individual pages
- **Extract Images**: Extract images from PDFs
- **Extract Text**: Extract text from PDFs

### Image Transformation
- **Resize**: Resize images with aspect ratio preservation
- **Rotate**: Rotate images by any angle
- **Crop**: Crop specific areas of images
- **Grayscale**: Convert to grayscale
- **Flip/Flop**: Mirror images horizontally or vertically
- **Blur**: Apply blur effects
- **Sharpen**: Enhance image sharpness
- **Negate**: Invert image colors

### Additional Features
- **Jobs Management**: Track all conversion/compression jobs
- **File Management**: Upload, download, and organize files
- **Notes**: Create and manage notes
- **Dark Mode**: Beautiful dark theme support
- **User Profiles**: Manage user accounts
- **Job History**: View past operations and results

## 📋 Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Node.js (v14 or higher) - for backend
- MongoDB (local or Atlas)

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/docxpress.git
cd docxpress/flutter_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Backend

See [BACKEND_SETUP.md](./BACKEND_SETUP.md) for detailed MongoDB and backend configuration.

### 4. Update Backend URL (if needed)

Edit `lib/core/constants/app_constants.dart`:

```dart
class AppConstants {
  static const String defaultBaseUrl = 'http://localhost:3000/api';
}
```

### 5. Run the App

```bash
# For Linux
flutter run -d linux

# For Chrome/Web
flutter run -d chrome

# For Android
flutter run -d android

# For iOS
flutter run -d ios
```

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/          # App constants and API endpoints
│   ├── router/             # GoRouter navigation configuration
│   ├── theme/              # App theming (light/dark)
│   └── utils/              # Utility functions
├── models/                 # Data models
├── providers/              # Riverpod state management
├── repositories/           # API and data repositories
├── screens/                # UI screens
│   ├── auth/              # Login/Register screens
│   ├── home/              # Home screen
│   ├── compress/          # Compression screens
│   ├── convert/           # Conversion screens
│   ├── jobs/              # Jobs management screens
│   ├── settings/          # Settings screen
│   └── ...
├── services/              # API service and utilities
└── widgets/               # Reusable widgets
```

## 🔧 Configuration

### API Endpoints

All API endpoints are configured in `lib/core/constants/app_constants.dart`:

```dart
class ApiEndpoints {
  static const String uploadFile = '/files/upload';
  static const String compressImage = '/compress/image';
  static const String convertImagesToPdf = '/convert/images-to-pdf';
  // ... more endpoints
}
```

### Theme Configuration

Customize app theme in `lib/core/theme/app_theme.dart`:

```dart
class AppTheme {
  static ThemeData get lightTheme { ... }
  static ThemeData get darkTheme { ... }
}
```

## 🔐 Authentication

The app uses JWT-based authentication:

1. **Register**: Create a new account with email and password
2. **Login**: Sign in with credentials
3. **Token Storage**: Tokens stored securely using `flutter_secure_storage`
4. **Auto-Refresh**: Tokens automatically refreshed when expired

## 📱 Supported Platforms

- ✅ Linux (Desktop)
- ✅ Web (Chrome, Firefox, Safari)
- ✅ Android
- ✅ iOS
- ✅ macOS
- ✅ Windows

## 🛠️ Development

### Run with Logging

```bash
flutter run -v
```

### Build Release

```bash
# Linux
flutter build linux --release

# Web
flutter build web --release

# Android
flutter build apk --release

# iOS
flutter build ios --release
```

### Run Tests

```bash
flutter test
```

### Code Analysis

```bash
flutter analyze
```

## 📦 Dependencies

Key packages used:

- **flutter_riverpod**: State management
- **go_router**: Navigation and routing
- **dio**: HTTP client
- **hive_flutter**: Local storage
- **flutter_secure_storage**: Secure token storage
- **google_fonts**: Typography
- **flutter_animate**: Animations
- **file_picker**: File selection
- **image_picker**: Image selection
- **intl**: Internationalization

See `pubspec.yaml` for complete list.

## 🐛 Troubleshooting

### App won't connect to backend

1. Ensure backend is running: `npm run dev`
2. Check backend URL in `AppConstants.defaultBaseUrl`
3. Verify MongoDB is running
4. Check network connectivity

### File upload fails

1. Ensure `UPLOAD_DIR` exists on backend
2. Check file size limits
3. Verify disk space available
4. Check file permissions

### Authentication issues

1. Clear app cache: `flutter clean`
2. Re-login to get new token
3. Check backend JWT configuration

## 📚 Documentation

- [Backend Setup Guide](./BACKEND_SETUP.md)
- [Implementation Status](./IMPLEMENTATION_STATUS.md)
- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Author

**Rahul Ranesh**

- GitHub: [@rahulranesh](https://github.com/rahulranesh)
- Email: ran@gmail.com

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Riverpod for state management
- All open-source contributors

## 📞 Support

For support, email ran@gmail.com or open an issue on GitHub.

## 🚀 Roadmap

- [ ] OCR text recognition
- [ ] Batch processing
- [ ] Cloud storage integration
- [ ] Advanced image editing
- [ ] Video preview
- [ ] Offline mode
- [ ] Multi-language support
- [ ] Advanced analytics

---

**Status**: ✅ Production Ready (with backend configuration)

**Last Updated**: November 30, 2025
