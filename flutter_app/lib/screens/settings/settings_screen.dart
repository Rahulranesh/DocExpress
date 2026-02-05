import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../providers/theme_provider.dart';
import '../../services/storage_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Load settings on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appSettingsNotifierProvider.notifier).loadSettings();
    });
  }

  void _showSnackBar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isSuccess ? AppTheme.successColor : AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _buildHeader(theme, isDark),
            ),

            // Settings sections
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Profile section
                  _buildProfileCard(theme, isDark),
                  const SizedBox(height: 24),

                  // Appearance
                  _buildSectionTitle(
                      'Appearance', Icons.palette_rounded, theme),
                  const SizedBox(height: 12),
                  _buildAppearanceSection(theme, isDark, themeMode),
                  const SizedBox(height: 24),

                  // General Settings
                  _buildSectionTitle('General', Icons.settings_rounded, theme),
                  const SizedBox(height: 12),
                  _buildGeneralSection(theme, isDark),
                  const SizedBox(height: 24),

                  // Storage
                  _buildSectionTitle('Storage', Icons.storage_rounded, theme),
                  const SizedBox(height: 12),
                  _buildStorageSection(theme, isDark),
                  const SizedBox(height: 24),

                  // About
                  _buildSectionTitle('About', Icons.info_rounded, theme),
                  const SizedBox(height: 12),
                  _buildAboutSection(theme, isDark),
                  const SizedBox(height: 24),

                  // Danger zone
                  _buildSectionTitle(
                      'Danger Zone', Icons.warning_rounded, theme,
                      color: AppTheme.errorColor),
                  const SizedBox(height: 12),
                  _buildDangerSection(theme, isDark),

                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        'Settings',
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1),
    );
  }

  Widget _buildProfileCard(ThemeData theme, bool isDark) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return GestureDetector(
      onTap: () => context.openProfile(),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.15),
              theme.colorScheme.primary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  user?.name.isNotEmpty == true
                      ? user!.name[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? 'Guest User',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'Not logged in',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildSectionTitle(String title, IconData icon, ThemeData theme,
      {Color? color}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(
      ThemeData theme, bool isDark, ThemeMode themeMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
        ),
      ),
      child: Column(
        children: [
          // Theme selection
          _SettingsTile(
            icon: Icons.brightness_6_rounded,
            title: 'Theme',
            subtitle: _getThemeLabel(themeMode),
            onTap: () => _showThemeSelector(theme, isDark, themeMode),
            isDark: isDark,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
  }

  Widget _buildGeneralSection(ThemeData theme, bool isDark) {
    final settings = ref.watch(appSettingsNotifierProvider);
    final qualityLabel = _getQualityLabel(settings.defaultImageQuality);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
        ),
      ),
      child: Column(
        children: [
          // Notifications
          _SettingsSwitch(
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            subtitle: 'Get notified when jobs complete',
            value: settings.notificationsEnabled,
            onChanged: (value) {
              ref
                  .read(appSettingsNotifierProvider.notifier)
                  .setNotificationsEnabled(value);
              _showSnackBar(
                  value ? 'Notifications enabled' : 'Notifications disabled');
            },
            isDark: isDark,
          ),
          _buildDivider(isDark),

          // Default quality
          _SettingsTile(
            icon: Icons.high_quality_rounded,
            title: 'Default Quality',
            subtitle: qualityLabel,
            onTap: () => _showQualitySelector(theme, isDark),
            isDark: isDark,
          ),
          _buildDivider(isDark),

          // Auto-delete completed
          _SettingsSwitch(
            icon: Icons.auto_delete_rounded,
            title: 'Auto-delete Completed',
            subtitle: 'Remove completed jobs after 7 days',
            value: settings.autoDeleteCompleted,
            onChanged: (value) {
              ref
                  .read(appSettingsNotifierProvider.notifier)
                  .setAutoDeleteCompleted(value);
              _showSnackBar(
                  value ? 'Auto-delete enabled' : 'Auto-delete disabled');
            },
            isDark: isDark,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms, duration: 300.ms);
  }

  String _getQualityLabel(int quality) {
    if (quality >= 80) return 'High';
    if (quality >= 50) return 'Medium';
    return 'Low';
  }

  Widget _buildStorageSection(ThemeData theme, bool isDark) {
    final settings = ref.watch(appSettingsNotifierProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
        ),
      ),
      child: Column(
        children: [
          // Storage location
          _SettingsTile(
            icon: Icons.folder_rounded,
            title: 'Storage Location',
            subtitle: settings.storageLocation == 'internal'
                ? 'Internal Storage'
                : 'External Storage',
            onTap: () => _showStorageSelector(theme, isDark),
            isDark: isDark,
          ),
          _buildDivider(isDark),

          // Storage usage
          _SettingsTile(
            icon: Icons.pie_chart_rounded,
            title: 'Storage Usage',
            subtitle: '245 MB used',
            onTap: () => _showStorageDetails(theme, isDark),
            isDark: isDark,
          ),
          _buildDivider(isDark),

          // Clear cache
          _SettingsTile(
            icon: Icons.cleaning_services_rounded,
            title: 'Clear Cache',
            subtitle: '12.5 MB',
            onTap: () => _clearCache(),
            isDark: isDark,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 300.ms);
  }

  Widget _buildAboutSection(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
        ),
      ),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Version',
            subtitle: '1.0.0 (Build 1)',
            onTap: null,
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _SettingsTile(
            icon: Icons.description_rounded,
            title: 'Terms of Service',
            onTap: () => _launchUrl('https://docxpress.app/terms'),
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _SettingsTile(
            icon: Icons.privacy_tip_rounded,
            title: 'Privacy Policy',
            onTap: () => _launchUrl('https://docxpress.app/privacy'),
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _SettingsTile(
            icon: Icons.star_rounded,
            title: 'Rate the App',
            onTap: () => _showRateAppDialog(theme, isDark),
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            onTap: () => _showHelpDialog(theme, isDark),
            isDark: isDark,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms, duration: 300.ms);
  }

  Widget _buildDangerSection(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.errorColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.delete_forever_rounded,
            title: 'Delete All Data',
            subtitle: 'Remove all files and history',
            onTap: () => _showDeleteDataDialog(theme, isDark),
            isDark: isDark,
            iconColor: AppTheme.errorColor,
            titleColor: AppTheme.errorColor,
          ),
          _buildDivider(isDark),
          _SettingsTile(
            icon: Icons.logout_rounded,
            title: 'Sign Out',
            onTap: () => _showSignOutDialog(theme, isDark),
            isDark: isDark,
            iconColor: AppTheme.errorColor,
            titleColor: AppTheme.errorColor,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 300.ms);
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not open URL', isSuccess: false);
      }
    } catch (e) {
      _showSnackBar('Could not open URL: $e', isSuccess: false);
    }
  }

  void _showRateAppDialog(ThemeData theme, bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Rate DocXpress'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'If you enjoy using DocXpress, please take a moment to rate it. Your feedback helps us improve!'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showSnackBar(
                          'Thank you for your ${index + 1}-star rating!');
                    },
                    icon: const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe Later'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog(ThemeData theme, bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Help & Support'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.email_rounded),
                title: const Text('Email Support'),
                subtitle: const Text('support@docxpress.app'),
                onTap: () {
                  Navigator.pop(context);
                  _launchUrl('mailto:support@docxpress.app');
                },
              ),
              ListTile(
                leading: const Icon(Icons.bug_report_rounded),
                title: const Text('Report a Bug'),
                onTap: () {
                  Navigator.pop(context);
                  _launchUrl('mailto:bugs@docxpress.app?subject=Bug%20Report');
                },
              ),
              ListTile(
                leading: const Icon(Icons.lightbulb_rounded),
                title: const Text('Feature Request'),
                onTap: () {
                  Navigator.pop(context);
                  _launchUrl(
                      'mailto:feedback@docxpress.app?subject=Feature%20Request');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showThemeSelector(ThemeData theme, bool isDark, ThemeMode currentMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Choose Theme',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _ThemeOption(
                icon: Icons.brightness_auto_rounded,
                title: 'System default',
                isSelected: currentMode == ThemeMode.system,
                onTap: () {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeModeSetting.system);
                  Navigator.pop(context);
                },
              ),
              _ThemeOption(
                icon: Icons.light_mode_rounded,
                title: 'Light',
                isSelected: currentMode == ThemeMode.light,
                onTap: () {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeModeSetting.light);
                  Navigator.pop(context);
                },
              ),
              _ThemeOption(
                icon: Icons.dark_mode_rounded,
                title: 'Dark',
                isSelected: currentMode == ThemeMode.dark,
                onTap: () {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeModeSetting.dark);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showQualitySelector(ThemeData theme, bool isDark) {
    final settings = ref.read(appSettingsNotifierProvider);
    final currentQuality = settings.defaultImageQuality;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Default Quality',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading:
                    const Icon(Icons.high_quality_rounded, color: Colors.green),
                title: const Text('High'),
                subtitle: const Text('Best quality, larger file size'),
                trailing: currentQuality >= 80
                    ? Icon(Icons.check_circle_rounded,
                        color: theme.colorScheme.primary)
                    : null,
                onTap: () {
                  ref
                      .read(appSettingsNotifierProvider.notifier)
                      .setDefaultQuality(90);
                  Navigator.pop(context);
                  _showSnackBar('Quality set to High');
                },
              ),
              ListTile(
                leading: const Icon(Icons.tune_rounded, color: Colors.orange),
                title: const Text('Medium'),
                subtitle: const Text('Balanced quality and size'),
                trailing: currentQuality >= 50 && currentQuality < 80
                    ? Icon(Icons.check_circle_rounded,
                        color: theme.colorScheme.primary)
                    : null,
                onTap: () {
                  ref
                      .read(appSettingsNotifierProvider.notifier)
                      .setDefaultQuality(60);
                  Navigator.pop(context);
                  _showSnackBar('Quality set to Medium');
                },
              ),
              ListTile(
                leading: const Icon(Icons.compress_rounded, color: Colors.red),
                title: const Text('Low'),
                subtitle: const Text('Smallest file size'),
                trailing: currentQuality < 50
                    ? Icon(Icons.check_circle_rounded,
                        color: theme.colorScheme.primary)
                    : null,
                onTap: () {
                  ref
                      .read(appSettingsNotifierProvider.notifier)
                      .setDefaultQuality(30);
                  Navigator.pop(context);
                  _showSnackBar('Quality set to Low');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showStorageSelector(ThemeData theme, bool isDark) {
    final settings = ref.read(appSettingsNotifierProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Storage Location',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.phone_android_rounded),
                title: const Text('Internal Storage'),
                trailing: settings.storageLocation == 'internal'
                    ? Icon(Icons.check_circle_rounded,
                        color: theme.colorScheme.primary)
                    : null,
                onTap: () {
                  ref
                      .read(appSettingsNotifierProvider.notifier)
                      .setStorageLocation('internal');
                  Navigator.pop(context);
                  _showSnackBar('Storage set to Internal');
                },
              ),
              ListTile(
                leading: const Icon(Icons.sd_card_rounded),
                title: const Text('External Storage'),
                trailing: settings.storageLocation == 'external'
                    ? Icon(Icons.check_circle_rounded,
                        color: theme.colorScheme.primary)
                    : null,
                onTap: () {
                  ref
                      .read(appSettingsNotifierProvider.notifier)
                      .setStorageLocation('external');
                  Navigator.pop(context);
                  _showSnackBar('Storage set to External');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showStorageDetails(ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Storage Usage',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _StorageItem(
                  icon: Icons.image_rounded,
                  label: 'Images',
                  size: '120 MB',
                  color: Colors.blue,
                  isDark: isDark,
                ),
                _StorageItem(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'PDFs',
                  size: '85 MB',
                  color: Colors.red,
                  isDark: isDark,
                ),
                _StorageItem(
                  icon: Icons.videocam_rounded,
                  label: 'Videos',
                  size: '28 MB',
                  color: Colors.purple,
                  isDark: isDark,
                ),
                _StorageItem(
                  icon: Icons.folder_rounded,
                  label: 'Other',
                  size: '12 MB',
                  color: Colors.grey,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
              isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Clear Cache'),
          content: const Text('This will clear all cached data. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final storageService = ref.read(storageServiceProvider);
                  await storageService.clearLocalStorage();
                  _showSnackBar('Cache cleared successfully');
                } catch (e) {
                  _showSnackBar('Failed to clear cache', isSuccess: false);
                }
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDataDialog(ThemeData theme, bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete All Data'),
          content: const Text(
            'This will permanently delete all your local data, settings, and log you out. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final storageService = ref.read(storageServiceProvider);
                  await storageService.clearAll();
                  _showSnackBar('All data deleted');
                  // Log out the user after clearing data
                  if (mounted) {
                    await ref.read(authStateProvider.notifier).logout();
                    context.goToLogin();
                  }
                } catch (e) {
                  _showSnackBar('Failed to delete data', isSuccess: false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showSignOutDialog(ThemeData theme, bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(authStateProvider.notifier).logout();
                if (mounted) {
                  context.goToLogin();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDark;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    required this.isDark,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ??
            (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: titleColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            )
          : null,
      trailing: onTap != null
          ? Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            )
          : null,
      onTap: onTap,
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _SettingsSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SwitchListTile(
      secondary: Icon(
        icon,
        color:
            isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color:
              isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}

class _StorageItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String size;
  final Color color;
  final bool isDark;

  const _StorageItem({
    required this.icon,
    required this.label,
    required this.size,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                Text(size, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
