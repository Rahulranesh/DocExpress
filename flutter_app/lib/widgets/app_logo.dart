import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// DocXpress DX Monogram App Icon - Premium Layered Design
/// Features: Multiple orbital rings, gradient depth, document accent
class AppLogoIcon extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppLogoIcon({
    super.key,
    this.size = 512,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = backgroundColor ?? theme.colorScheme.primary;
    final fg = foregroundColor ?? Colors.white;
    final radius = size * 0.24;

    // Color variations for depth
    final primaryLight = Color.lerp(primary, Colors.white, 0.15)!;
    final primaryDark = Color.lerp(primary, Colors.black, 0.3)!;
    final accentGlow = Color.lerp(primary, Colors.amber, 0.2)!;

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
          // Outer glow
          BoxShadow(
            color: primary.withOpacity(0.5),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.06),
          ),
          // Inner highlight
          BoxShadow(
            color: primaryLight.withOpacity(0.3),
            blurRadius: size * 0.05,
            offset: Offset(-size * 0.02, -size * 0.02),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background radial gradient overlay
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
            
            // Outer orbital ring 1 (largest)
            CustomPaint(
              size: Size(size, size),
              painter: _OrbitalRingPainter(
                color: fg.withOpacity(0.08),
                strokeWidth: size * 0.012,
                radiusFactor: 0.44,
                rotation: -15,
              ),
            ),
            
            // Outer orbital ring 2
            CustomPaint(
              size: Size(size, size),
              painter: _OrbitalRingPainter(
                color: fg.withOpacity(0.12),
                strokeWidth: size * 0.015,
                radiusFactor: 0.38,
                rotation: 25,
                dashPattern: true,
              ),
            ),
            
            // Middle orbital ring (prominent)
            CustomPaint(
              size: Size(size, size),
              painter: _OrbitalRingPainter(
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
                boxShadow: [
                  BoxShadow(
                    color: accentGlow.withOpacity(0.25),
                    blurRadius: size * 0.08,
                    spreadRadius: size * 0.01,
                  ),
                ],
              ),
            ),
            
            // Center circle backdrop
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
            
            // DX Monogram with shadow
            Text(
              'DX',
              style: GoogleFonts.poppins(
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
            
            // Document page accent (top-right)
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
                      // Document lines
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
            
            // Processing arrow accent (bottom-left)
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
            
            // Subtle corner accents
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

/// Custom painter for orbital rings with optional dash pattern
class _OrbitalRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radiusFactor;
  final double rotation;
  final bool dashPattern;

  _OrbitalRingPainter({
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
      // Draw dashed arc
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
      // Draw partial arc for depth effect
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
  bool shouldRepaint(_OrbitalRingPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.radiusFactor != radiusFactor;
}

/// App Logo - Premium DX icon with orbital rings + "DocXpress" text
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool compact;

  const AppLogo({
    super.key,
    this.size = 48,
    this.showText = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final radius = size * 0.24;

    // Color variations
    final primaryLight = Color.lerp(primary, Colors.white, 0.15)!;
    final primaryDark = Color.lerp(primary, Colors.black, 0.3)!;

    final iconWidget = Container(
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
            color: primary.withOpacity(0.4),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Radial glow
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.4),
                  radius: 1.2,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            
            // Outer ring
            CustomPaint(
              size: Size(size, size),
              painter: _OrbitalRingPainter(
                color: Colors.white.withOpacity(0.12),
                strokeWidth: size * 0.015,
                radiusFactor: 0.36,
                rotation: 20,
              ),
            ),
            
            // Inner ring
            CustomPaint(
              size: Size(size, size),
              painter: _OrbitalRingPainter(
                color: Colors.white.withOpacity(0.18),
                strokeWidth: size * 0.02,
                radiusFactor: 0.28,
                rotation: -35,
              ),
            ),
            
            // Center glow
            Container(
              width: size * 0.44,
              height: size * 0.44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            
            // DX text
            Text(
              'DX',
              style: GoogleFonts.poppins(
                fontSize: size * 0.32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -size * 0.008,
                height: 1,
                shadows: [
                  Shadow(
                    color: primaryDark.withOpacity(0.4),
                    blurRadius: size * 0.02,
                    offset: Offset(size * 0.008, size * 0.01),
                  ),
                ],
              ),
            ),
            
            // Small accent dot
            Positioned(
              right: size * 0.12,
              bottom: size * 0.12,
              child: Container(
                width: size * 0.12,
                height: size * 0.12,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: size * 0.01,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (compact || !showText) return iconWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        iconWidget,
        SizedBox(width: size * 0.2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Doc',
                    style: GoogleFonts.poppins(
                      fontSize: size * 0.40,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.5,
                      height: 1,
                    ),
                  ),
                  TextSpan(
                    text: 'Xpress',
                    style: GoogleFonts.poppins(
                      fontSize: size * 0.40,
                      fontWeight: FontWeight.w700,
                      color: primary,
                      letterSpacing: -0.5,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Smart Document Tools',
              style: GoogleFonts.poppins(
                fontSize: size * 0.17,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white54 : Colors.black45,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Welcome Banner — blends directly into the AppBar gradient background (no card/shadow)
class WelcomeBanner extends StatelessWidget {
  const WelcomeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    // Text colour: white on dark or strong-primary bg, else dark
    final onBg = isDark
        ? Colors.white
        : HSLColor.fromColor(primary).lightness < 0.55
            ? Colors.white
            : Colors.black87;
    final onBgSub = onBg.withOpacity(0.6);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // thin divider line to separate greeting from banner content
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  onBg.withOpacity(0.0),
                  onBg.withOpacity(0.12),
                  onBg.withOpacity(0.0),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pill badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(isDark ? 0.35 : 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded,
                              size: 12, color: primary),
                          const SizedBox(width: 4),
                          Text(
                            'Your Productivity Suite',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Smart Document\nCompanion',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: onBg,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Convert · Compress · Scan · Share',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: onBgSub,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              // Right: big DX watermark glyph
              Text(
                'DX',
                style: GoogleFonts.poppins(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: primary.withOpacity(isDark ? 0.18 : 0.10),
                  letterSpacing: -4,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
