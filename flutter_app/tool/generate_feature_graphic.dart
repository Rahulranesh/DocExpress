// Run this script to generate the Google Play Store Feature Graphic (1024x500)
// Usage: flutter run -t tool/generate_feature_graphic.dart

import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const FeatureGraphicGeneratorApp());
}

class FeatureGraphicGeneratorApp extends StatelessWidget {
  const FeatureGraphicGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FeatureGraphicGeneratorScreen(),
    );
  }
}

class FeatureGraphicGeneratorScreen extends StatefulWidget {
  @override
  State<FeatureGraphicGeneratorScreen> createState() => 
      _FeatureGraphicGeneratorScreenState();
}

class _FeatureGraphicGeneratorScreenState 
    extends State<FeatureGraphicGeneratorScreen> {
  final GlobalKey _graphicKey = GlobalKey();
  String _status = 'Tap button to generate feature graphic';

  Future<void> _generateGraphic() async {
    setState(() => _status = 'Generating...');
    
    try {
      // Wait for widget to render
      await Future.delayed(const Duration(milliseconds: 500));
      
      RenderRepaintBoundary boundary = 
          _graphicKey.currentContext!.findRenderObject() 
          as RenderRepaintBoundary;
      
      // Generate at 1024x500 (pixel ratio 1.0)
      ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      
      // Save to documents directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/feature_graphic.png');
      await file.writeAsBytes(pngBytes);
      
      setState(() => _status = 
          'Feature Graphic saved to:\n${file.path}\n\n'
          'Upload to Google Play Console > Store Listing > Graphics'
      );
      
      print('========================================');
      print('FEATURE GRAPHIC GENERATED!');
      print('Location: ${file.path}');
      print('Size: 1024x500px');
      print('');
      print('To upload to Google Play Console:');
      print('1. Go to Google Play Console > Your App > Store Listing');
      print('2. Scroll to "Graphics"');
      print('3. Upload this file as "Feature Graphic"');
      print('========================================');
      
    } catch (e) {
      setState(() => _status = 'Error: $e');
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Feature Graphic (1024x500)'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // Preview of the feature graphic
              RepaintBoundary(
                key: _graphicKey,
                child: Container(
                  width: 1024,
                  height: 500,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1E3C72),
                        const Color(0xFF2A5298),
                        const Color(0xFF00D4FF).withAlpha(80),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Background decorative circles
                      Positioned(
                        right: -100,
                        top: -100,
                        child: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00D4FF).withAlpha(30),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -50,
                        bottom: -80,
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00FF88).withAlpha(20),
                          ),
                        ),
                      ),
                      // Main content
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 60,
                          vertical: 50,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left side - Icon
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withAlpha(15),
                                    border: Border.all(
                                      color: Colors.white.withAlpha(50),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.description_outlined,
                                    size: 120,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 40),
                            // Right side - Text
                            Expanded(
                              flex: 1,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'DocXpress',
                                    style: TextStyle(
                                      fontSize: 64,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  RichText(
                                    text: const TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Convert ',
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Color(0xFF00D4FF),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '& ',
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Create',
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Color(0xFF00FF88),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    height: 4,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF00D4FF),
                                          const Color(0xFF00FF88),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    '• Scan & Extract Text\n'
                                    '• Convert to PDF/Word\n'
                                    '• Compress & Share',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _generateGraphic,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: const Color(0xFF2A5298),
                ),
                child: const Text(
                  'Generate Feature Graphic (1024×500)',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
