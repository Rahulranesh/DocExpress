// Run this script to generate the new app icon PNG
// Usage: flutter run -t tool/generate_app_icon.dart

import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const IconGeneratorApp());
}

class IconGeneratorApp extends StatelessWidget {
  const IconGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: IconGeneratorScreen(),
    );
  }
}

class IconGeneratorScreen extends StatefulWidget {
  @override
  State<IconGeneratorScreen> createState() => _IconGeneratorScreenState();
}

class _IconGeneratorScreenState extends State<IconGeneratorScreen> {
  final GlobalKey _iconKey = GlobalKey();
  String _status = 'Tap button to generate icon';

  Future<void> _generateIcon() async {
    setState(() => _status = 'Generating...');
    
    try {
      // Wait for widget to render
      await Future.delayed(const Duration(milliseconds: 500));
      
      RenderRepaintBoundary boundary = 
          _iconKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      ui.Image image = await boundary.toImage(pixelRatio: 2.0); // 1024px output
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      
      // Save to documents directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/app_icon_new.png');
      await file.writeAsBytes(pngBytes);
      
      setState(() => _status = 'Icon saved to:\n${file.path}\n\nCopy this file to assets/icons/app_icon.png');
      
      print('========================================');
      print('NEW APP ICON GENERATED!');
      print('Location: ${file.path}');
      print('');
      print('To update launcher icon:');
      print('1. Copy the generated file to assets/icons/app_icon.png');
      print('2. Run: flutter pub run flutter_launcher_icons');
      print('========================================');
      
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate App Icon')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Preview of the icon
            RepaintBoundary(
              key: _iconKey,
              child: const PremiumAppIcon(size: 512),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _generateIcon,
              child: const Text('Generate Icon PNG'),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_status, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium App Icon - Layered design with DX monogram
class PremiumAppIcon extends StatelessWidget {
  final double size;
  
  const PremiumAppIcon({super.key, this.size = 512});

  @override
  Widget build(BuildContext context) {
    // DocXpress brand orange
    const primary = Color(0xFFF97316);
    final primaryLight = Color.lerp(primary, Colors.white, 0.15)!;
    final primaryDark = Color.lerp(primary, Colors.black, 0.3)!;
    const fg = Colors.white;
    final radius = size * 0.24;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryLight, primary, primaryDark],
          stops: const [0.0, 0.4, 1.0],
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.5),
            blurRadius: size * 0.15,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background radial gradient
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.4),
                  radius: 1.2,
                  colors: [
                    fg.withOpacity(0.12),
                    Colors.transparent,
                    primaryDark.withOpacity(0.3),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            
            // Outer orbital ring 1
            CustomPaint(
              size: Size(size, size),
              painter: OrbitalRingPainter(
                color: fg.withOpacity(0.08),
                strokeWidth: size * 0.012,
                radiusFactor: 0.44,
                rotation: -15,
              ),
            ),
            
            // Outer orbital ring 2 (dashed)
            CustomPaint(
              size: Size(size, size),
              painter: OrbitalRingPainter(
                color: fg.withOpacity(0.12),
                strokeWidth: size * 0.015,
                radiusFactor: 0.38,
                rotation: 25,
                dashPattern: true,
              ),
            ),
            
            // Middle orbital ring
            CustomPaint(
              size: Size(size, size),
              painter: OrbitalRingPainter(
                color: fg.withOpacity(0.18),
                strokeWidth: size * 0.02,
                radiusFactor: 0.32,
                rotation: -40,
              ),
            ),
            
            // Inner glow ring
            Container(
              width: size * 0.52,
              height: size * 0.52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: fg.withOpacity(0.15),
                  width: size * 0.008,
                ),
              ),
            ),
            
            // Center backdrop
            Container(
              width: size * 0.46,
              height: size * 0.46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    fg.withOpacity(0.12),
                    fg.withOpacity(0.04),
                  ],
                ),
              ),
            ),
            
            // DX Monogram
            Text(
              'DX',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: size * 0.32,
                fontWeight: FontWeight.w900,
                color: fg,
                letterSpacing: -size * 0.01,
                height: 1,
                shadows: [
                  Shadow(
                    color: primaryDark.withOpacity(0.4),
                    blurRadius: size * 0.03,
                    offset: Offset(size * 0.01, size * 0.015),
                  ),
                ],
              ),
            ),
            
            // Document accent (top-right)
            Positioned(
              right: size * 0.11,
              top: size * 0.11,
              child: Transform.rotate(
                angle: 0.15,
                child: Container(
                  width: size * 0.12,
                  height: size * 0.15,
                  decoration: BoxDecoration(
                    color: fg.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(size * 0.02),
                    boxShadow: [
                      BoxShadow(
                        color: primaryDark.withOpacity(0.3),
                        blurRadius: size * 0.02,
                        offset: Offset(size * 0.005, size * 0.008),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: size * 0.07,
                        height: size * 0.012,
                        margin: EdgeInsets.only(bottom: size * 0.012),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(size * 0.01),
                        ),
                      ),
                      Container(
                        width: size * 0.055,
                        height: size * 0.012,
                        margin: EdgeInsets.only(bottom: size * 0.012),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(size * 0.01),
                        ),
                      ),
                      Container(
                        width: size * 0.07,
                        height: size * 0.012,
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(size * 0.01),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Processing icon (bottom-left)
            Positioned(
              left: size * 0.10,
              bottom: size * 0.12,
              child: Container(
                width: size * 0.16,
                height: size * 0.16,
                decoration: BoxDecoration(
                  color: fg.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: fg.withOpacity(0.25),
                    width: size * 0.006,
                  ),
                ),
                child: Icon(
                  Icons.sync_rounded,
                  size: size * 0.09,
                  color: fg.withOpacity(0.9),
                ),
              ),
            ),
            
            // Corner accents
            Positioned(
              left: size * 0.06,
              top: size * 0.06,
              child: Container(
                width: size * 0.04,
                height: size * 0.04,
                decoration: BoxDecoration(
                  color: fg.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: size * 0.06,
              bottom: size * 0.06,
              child: Container(
                width: size * 0.03,
                height: size * 0.03,
                decoration: BoxDecoration(
                  color: fg.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrbitalRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radiusFactor;
  final double rotation;
  final bool dashPattern;

  OrbitalRingPainter({
    required this.color,
    required this.strokeWidth,
    required this.radiusFactor,
    this.rotation = 0,
    this.dashPattern = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * radiusFactor;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * math.pi / 180);
    canvas.translate(-center.dx, -center.dy);

    if (dashPattern) {
      const dashLength = 0.15;
      const gapLength = 0.1;
      double startAngle = 0;
      while (startAngle < 2 * math.pi) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          dashLength,
          false,
          paint,
        );
        startAngle += dashLength + gapLength;
      }
    } else {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        0.3,
        math.pi * 1.4,
        false,
        paint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(OrbitalRingPainter old) => false;
}
