# Backend Conversion Service - Usage Examples

This document shows how to use the backend conversion service in your Flutter app for features that cannot be done locally.

## Setup

### 1. Initialize Services

```dart
import 'package:docxpress/services/storage_service.dart';
import 'package:docxpress/services/api_service.dart';
import 'package:docxpress/repositories/backend_conversion_repository.dart';

// Initialize services (usually done in main.dart or with dependency injection)
final storageService = StorageService();
final apiService = ApiService(storageService: storageService);
final backendRepo = BackendConversionRepository(apiService);
```

### 2. Configure API Base URL

Update `lib/core/constants/app_constants.dart`:

```dart
class AppConstants {
  // Development - Android Emulator
  static const String defaultBaseUrl = 'http://10.0.2.2:3000/api';
  
  // Development - iOS Simulator
  // static const String defaultBaseUrl = 'http://localhost:3000/api';
  
  // Development - Physical Device (replace with your computer's IP)
  // static const String defaultBaseUrl = 'http://192.168.1.100:3000/api';
  
  // Production
  // static const String defaultBaseUrl = 'https://api.yourdomain.com/api';
}
```

## Usage Examples

### Extract Images from PDF

```dart
import 'package:flutter/material.dart';

class PdfImageExtractorScreen extends StatefulWidget {
  final String pdfPath;
  
  const PdfImageExtractorScreen({Key? key, required this.pdfPath}) : super(key: key);

  @override
  State<PdfImageExtractorScreen> createState() => _PdfImageExtractorScreenState();
}

class _PdfImageExtractorScreenState extends State<PdfImageExtractorScreen> {
  bool _isLoading = false;
  List<String>? _extractedImages;
  String? _error;

  Future<void> _extractImages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final images = await backendRepo.extractImagesFromPdf(widget.pdfPath);
      
      setState(() {
        _extractedImages = images;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Extracted ${images.length} images')),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Extract Images from PDF')),
      body: Column(
        children: [
          if (_isLoading)
            const LinearProgressIndicator(),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _extractImages,
              child: const Text('Extract Images'),
            ),
          ),

          if (_extractedImages != null)
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _extractedImages!.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.file(
                            File(_extractedImages![index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text('Page ${index + 1}'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
```

### Convert DOCX to PDF

```dart
Future<void> convertDocxToPdf(BuildContext context, String docxPath) async {
  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Converting DOCX to PDF...'),
        ],
      ),
    ),
  );

  try {
    final pdfPath = await backendRepo.convertDocxToPdf(docxPath);
    
    Navigator.pop(context); // Close loading dialog

    // Show success and open PDF
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conversion successful!')),
    );

    // Open the PDF file
    await OpenFilex.open(pdfPath);
  } catch (e) {
    Navigator.pop(context); // Close loading dialog

    // Show error
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conversion Failed'),
        content: Text(e.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

### Convert PPTX to PDF

```dart
Future<void> convertPptxToPdf(BuildContext context, String pptxPath) async {
  try {
    // Show loading indicator
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Converting PPTX to PDF...'),
        duration: Duration(hours: 1), // Keep showing until dismissed
      ),
    );

    final pdfPath = await backendRepo.convertPptxToPdf(pptxPath);
    
    // Dismiss loading snackbar
    scaffoldMessenger.hideCurrentSnackBar();

    // Show success
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Converted to: ${path.basename(pdfPath)}'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () => OpenFilex.open(pdfPath),
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### Convert PDF to PPTX

```dart
class PdfToPptxConverter extends StatefulWidget {
  final String pdfPath;

  const PdfToPptxConverter({Key? key, required this.pdfPath}) : super(key: key);

  @override
  State<PdfToPptxConverter> createState() => _PdfToPptxConverterState();
}

class _PdfToPptxConverterState extends State<PdfToPptxConverter> {
  bool _isConverting = false;
  double _progress = 0.0;

  Future<void> _convert() async {
    setState(() {
      _isConverting = true;
      _progress = 0.0;
    });

    try {
      // Simulate progress (actual progress tracking would require backend support)
      Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (_progress < 0.9) {
          setState(() => _progress += 0.1);
        }
      });

      final pptxPath = await backendRepo.convertPdfToPptx(widget.pdfPath);
      
      setState(() {
        _isConverting = false;
        _progress = 1.0;
      });

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Conversion Complete'),
          content: Text('Saved to: ${path.basename(pptxPath)}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                OpenFilex.open(pptxPath);
              },
              child: const Text('Open'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isConverting = false;
        _progress = 0.0;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Conversion Failed'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Convert PDF to PowerPoint',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Each PDF page will become a slide',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            if (_isConverting) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text(
                '${(_progress * 100).toInt()}% complete',
                textAlign: TextAlign.center,
              ),
            ] else
              ElevatedButton.icon(
                onPressed: _convert,
                icon: const Icon(Icons.slideshow),
                label: const Text('Convert to PPTX'),
              ),
          ],
        ),
      ),
    );
  }
}
```

### Convert PDF to DOCX

```dart
Future<void> convertPdfToDocx(BuildContext context, String pdfPath) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Convert PDF to Word'),
      content: const Text(
        'This will extract text from the PDF and create a Word document. '
        'Images and complex formatting may not be preserved.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Convert'),
        ),
      ],
    ),
  );

  if (result != true) return;

  try {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Converting PDF to DOCX...'),
                SizedBox(height: 8),
                Text(
                  'This may take a few moments',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final docxPath = await backendRepo.convertPdfToDocx(pdfPath);
    
    Navigator.pop(context); // Close loading

    // Show success with options
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conversion Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Word document is ready!'),
            const SizedBox(height: 8),
            Text(
              path.basename(docxPath),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              OpenFilex.open(docxPath);
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open'),
          ),
        ],
      ),
    );
  } catch (e) {
    Navigator.pop(context); // Close loading if open

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conversion Failed'),
        content: Text(e.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

## Error Handling

### Network Errors

```dart
try {
  final result = await backendRepo.convertDocxToPdf(docxPath);
  // Handle success
} on ApiException catch (e) {
  if (e.isUnauthorized) {
    // Redirect to login
    Navigator.pushReplacementNamed(context, '/login');
  } else if (e.code == 'NO_CONNECTION') {
    // Show offline message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Internet Connection'),
        content: const Text(
          'Please check your internet connection and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  } else {
    // Show generic error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.message}')),
    );
  }
} catch (e) {
  // Handle unexpected errors
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Unexpected error: $e')),
  );
}
```

### Timeout Handling

```dart
try {
  final result = await backendRepo.convertPdfToPptx(pdfPath)
      .timeout(const Duration(minutes: 5));
  // Handle success
} on TimeoutException {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Conversion Timeout'),
      content: const Text(
        'The conversion is taking longer than expected. '
        'This might be due to a large file or slow connection.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
```

## Best Practices

1. **Always show loading indicators** - Conversions can take time
2. **Handle errors gracefully** - Network issues are common
3. **Provide feedback** - Let users know what's happening
4. **Clean up resources** - Delete temporary files when done
5. **Test with various file sizes** - Large files may timeout
6. **Implement retry logic** - For transient network errors
7. **Cache results** - Avoid redundant conversions

## Testing

### Test with Mock Data

```dart
// For testing without backend
class MockBackendConversionRepository implements BackendConversionRepository {
  @override
  Future<List<String>> extractImagesFromPdf(String pdfPath) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
    return ['/mock/image1.png', '/mock/image2.png'];
  }

  @override
  Future<String> convertDocxToPdf(String docxPath, {String? outputName}) async {
    await Future.delayed(const Duration(seconds: 3));
    return '/mock/converted.pdf';
  }

  // ... implement other methods
}
```

## Performance Tips

1. **Compress files before upload** - Reduces upload time
2. **Show progress indicators** - Improves user experience
3. **Implement caching** - Avoid redundant conversions
4. **Use background processing** - Don't block the UI
5. **Batch operations** - Convert multiple files efficiently

## Support

For issues:
1. Check backend logs
2. Verify API endpoint URLs
3. Test with curl/Postman
4. Check network connectivity
5. Review error messages
