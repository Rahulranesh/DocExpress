import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/app_constants.dart';
import '../models/models.dart';

/// Theme mode notifier - manages theme state
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  /// Load theme mode from storage
  Future<void> _loadThemeMode() async {
    try {
      final box = Hive.box('settings');
      final index = box.get(AppConstants.themeKey, defaultValue: 2);
      final themeSetting = ThemeModeSetting.values[index];
      state = _themeSettingToThemeMode(themeSetting);
    } catch (e) {
      state = ThemeMode.system;
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeModeSetting setting) async {
    try {
      final box = Hive.box('settings');
      await box.put(AppConstants.themeKey, setting.index);
      state = _themeSettingToThemeMode(setting);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newSetting = state == ThemeMode.dark
        ? ThemeModeSetting.light
        : ThemeModeSetting.dark;
    await setThemeMode(newSetting);
  }

  /// Convert ThemeModeSetting to ThemeMode
  ThemeMode _themeSettingToThemeMode(ThemeModeSetting setting) {
    switch (setting) {
      case ThemeModeSetting.light:
        return ThemeMode.light;
      case ThemeModeSetting.dark:
        return ThemeMode.dark;
      case ThemeModeSetting.system:
        return ThemeMode.system;
    }
  }

  /// Get current theme setting
  ThemeModeSetting get currentSetting {
    switch (state) {
      case ThemeMode.light:
        return ThemeModeSetting.light;
      case ThemeMode.dark:
        return ThemeModeSetting.dark;
      case ThemeMode.system:
        return ThemeModeSetting.system;
    }
  }
}

/// Theme mode provider
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Theme setting provider - for UI selection
final themeSettingProvider = Provider<ThemeModeSetting>((ref) {
  final notifier = ref.watch(themeModeProvider.notifier);
  return notifier.currentSetting;
});

/// Is dark mode provider
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  return themeMode == ThemeMode.dark;
});

/// Brightness provider based on current theme
final brightnessProvider = Provider.family<Brightness, BuildContext>((ref, context) {
  final themeMode = ref.watch(themeModeProvider);
  switch (themeMode) {
    case ThemeMode.light:
      return Brightness.light;
    case ThemeMode.dark:
      return Brightness.dark;
    case ThemeMode.system:
      return MediaQuery.platformBrightnessOf(context);
  }
});
