import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../providers/theme_provider.dart';

/// Cute theme guide dialog that shows users about theme customization
class ThemeGuideDialog extends ConsumerStatefulWidget {
  const ThemeGuideDialog({super.key});

  static const String _shownKey = 'theme_guide_shown';

  /// Check if guide has been shown before
  static Future<bool> hasBeenShown() async {
    try {
      final box = Hive.box('settings');
      return box.get(_shownKey, defaultValue: false);
    } catch (e) {
      return false;
    }
  }

  /// Mark guide as shown
  static Future<void> markAsShown() async {
    try {
      final box = Hive.box('settings');
      await box.put(_shownKey, true);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Show the guide dialog
  static Future<void> show(BuildContext context) async {
    final hasShown = await hasBeenShown();
    if (!hasShown && context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => const ThemeGuideDialog(),
      );
      await markAsShown();
    }
  }

  @override
  ConsumerState<ThemeGuideDialog> createState() => _ThemeGuideDialogState();
}

class _ThemeGuideDialogState extends ConsumerState<ThemeGuideDialog> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                padding: const EdgeInsets.all(16),
              ),
            ).animate().fadeIn(delay: 200.ms),

            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomePage(theme, isDark),
                  _buildThemesPage(theme, isDark),
                  _buildModesPage(theme, isDark),
                ],
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? theme.colorScheme.primary
                          : (isDark
                              ? AppTheme.darkDivider
                              : AppTheme.lightDivider),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: _currentPage == 0 ? 1 : 1,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < 2) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(_currentPage < 2 ? 'Next' : 'Got it! 🎉'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated emoji
          Text(
            '🎨',
            style: const TextStyle(fontSize: 80),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 2000.ms, delay: 500.ms)
              .shake(duration: 1000.ms, delay: 2500.ms),

          const SizedBox(height: 24),

          Text(
            'Welcome to DocXpress!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms, duration: 500.ms),

          const SizedBox(height: 16),

          Text(
            'We\'ve got something special for you! ✨',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.1),
                  theme.colorScheme.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  'Personalize Your Experience',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose from beautiful themes and switch between light & dark modes!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 500.ms).scale(
                begin: const Offset(0.9, 0.9),
                duration: 500.ms,
              ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildThemesPage(ThemeData theme, bool isDark) {
    final currentPalette = ref.watch(colorPaletteProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            '🌈',
            style: const TextStyle(fontSize: 64),
          ).animate().scale(duration: 500.ms),

          const SizedBox(height: 16),

          Text(
            'Multiple Color Themes',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms, duration: 500.ms),

          const SizedBox(height: 12),

          Text(
            'Pick your favorite color palette to match your style!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

          const SizedBox(height: 24),

          // Theme palette grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: ColorPalette.values.length,
            itemBuilder: (context, index) {
              final palette = ColorPalette.values[index];
              final colors = AppTheme.palettes[palette]!;
              final isSelected = palette == currentPalette;

              return GestureDetector(
                onTap: () {
                  ref.read(colorPaletteProvider.notifier).setPalette(palette);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.primary,
                        colors.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colors.primary.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        colors.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        colors.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 16,
                        ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (index * 50).ms, duration: 400.ms);
            },
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap the palette icon 🎨 anytime to change themes!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildModesPage(ThemeData theme, bool isDark) {
    final themeMode = ref.watch(themeModeProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '☀️',
                style: const TextStyle(fontSize: 48),
              ).animate().fadeIn(duration: 500.ms),
              const SizedBox(width: 16),
              Text(
                '🌙',
                style: const TextStyle(fontSize: 48),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            'Light & Dark Modes',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms, duration: 500.ms),

          const SizedBox(height: 12),

          Text(
            'Switch between light and dark modes for comfortable viewing anytime!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

          const SizedBox(height: 32),

          // Mode options
          _buildModeOption(
            theme,
            isDark,
            icon: Icons.light_mode_rounded,
            title: 'Light Mode',
            description: 'Bright and clear',
            emoji: '☀️',
            isSelected: themeMode == ThemeMode.light,
            onTap: () {
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(ThemeModeSetting.light);
            },
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideX(
                begin: -0.1,
                duration: 400.ms,
              ),

          const SizedBox(height: 12),

          _buildModeOption(
            theme,
            isDark,
            icon: Icons.dark_mode_rounded,
            title: 'Dark Mode',
            description: 'Easy on the eyes',
            emoji: '🌙',
            isSelected: themeMode == ThemeMode.dark,
            onTap: () {
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(ThemeModeSetting.dark);
            },
          ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideX(
                begin: -0.1,
                duration: 400.ms,
              ),

          const SizedBox(height: 12),

          _buildModeOption(
            theme,
            isDark,
            icon: Icons.brightness_auto_rounded,
            title: 'Auto Mode',
            description: 'Follows system settings',
            emoji: '🔄',
            isSelected: themeMode == ThemeMode.system,
            onTap: () {
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(ThemeModeSetting.system);
            },
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideX(
                begin: -0.1,
                duration: 400.ms,
              ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Change theme settings anytime from your Profile!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 500.ms),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildModeOption(
    ThemeData theme,
    bool isDark, {
    required IconData icon,
    required String title,
    required String description,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : (isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : (isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(0.2)
                    : (isDark
                        ? AppTheme.darkBackground
                        : AppTheme.lightBackground),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
