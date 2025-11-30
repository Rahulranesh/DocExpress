import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize storage service
    final storageService = ref.read(storageServiceProvider);
    await storageService.init();

    // Load saved settings
    final settings = await storageService.getAppSettings();

    // Update base URL if different from default
    final apiService = ref.read(apiServiceProvider);
    apiService.updateBaseUrl(settings.baseUrl);

    // Initialize auth state
    await ref.read(authStateProvider.notifier).initialize();

    // Small delay for splash animation
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Navigate based on auth state
    final authState = ref.read(authStateProvider);
    if (authState.isAuthenticated) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1E293B),
                    const Color(0xFF0F172A),
                  ]
                : [
                    AppTheme.primaryLight.withOpacity(0.1),
                    Colors.white,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.document_scanner_rounded,
                  size: 72,
                  color: Colors.white,
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  ),

              const SizedBox(height: 32),

              // App name
              Text(
                'DocXpress',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 600.ms)
                  .slideY(begin: 0.3, duration: 600.ms),

              const SizedBox(height: 8),

              // Tagline
              Text(
                'Scan • Convert • Compress',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark
                      ? Colors.white.withOpacity(0.7)
                      : AppTheme.lightTextSecondary,
                  letterSpacing: 2,
                ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 600.ms)
                  .slideY(begin: 0.3, duration: 600.ms),

              const Spacer(flex: 2),

              // Loading indicator
              SizedBox(
                width: 200,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        backgroundColor: isDark
                            ? Colors.white.withOpacity(0.1)
                            : AppTheme.primaryColor.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? Colors.white.withOpacity(0.5)
                            : AppTheme.lightTextHint,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 700.ms, duration: 500.ms),

              const SizedBox(height: 48),

              // Version
              Text(
                'Version 1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? Colors.white.withOpacity(0.3)
                      : AppTheme.lightTextHint.withOpacity(0.7),
                ),
              )
                  .animate()
                  .fadeIn(delay: 900.ms, duration: 500.ms),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
