import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/notification_settings.dart';

/// Notification preferences screen
class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  late NotificationSettings _settings;

  @override
  void initState() {
    super.initState();
    // TODO: Load settings from storage
    _settings = const NotificationSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            'Notification Types',
            [
              _buildSwitch(
                'Job Completion',
                'Notify when jobs complete successfully',
                _settings.jobCompletionEnabled,
                (value) => _updateSettings(_settings.copyWith(jobCompletionEnabled: value)),
                isDark,
              ),
              _buildSwitch(
                'Job Failure',
                'Notify when jobs fail',
                _settings.jobFailureEnabled,
                (value) => _updateSettings(_settings.copyWith(jobFailureEnabled: value)),
                isDark,
              ),
              _buildSwitch(
                'Progress Updates',
                'Show progress for long-running jobs',
                _settings.progressEnabled,
                (value) => _updateSettings(_settings.copyWith(progressEnabled: value)),
                isDark,
              ),
            ],
            isDark,
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Notification Behavior',
            [
              _buildSwitch(
                'Sound',
                'Play sound for notifications',
                _settings.soundEnabled,
                (value) => _updateSettings(_settings.copyWith(soundEnabled: value)),
                isDark,
              ),
              _buildSwitch(
                'Vibration',
                'Vibrate for notifications',
                _settings.vibrationEnabled,
                (value) => _updateSettings(_settings.copyWith(vibrationEnabled: value)),
                isDark,
              ),
              _buildSwitch(
                'Show in Foreground',
                'Show notifications when app is open',
                _settings.showInForeground,
                (value) => _updateSettings(_settings.copyWith(showInForeground: value)),
                isDark,
              ),
            ],
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitch(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
  ) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white60 : Colors.black54,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  void _updateSettings(NotificationSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    // TODO: Save settings to storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preferences updated'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
