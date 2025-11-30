import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/app_constants.dart';
import '../models/models.dart';

/// Storage Service - handles secure storage and local preferences
class StorageService {
  final FlutterSecureStorage _secureStorage;
  late Box _settingsBox;
  bool _initialized = false;

  StorageService({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  /// Initialize storage
  Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();
    _settingsBox = await Hive.openBox('settings');
    _initialized = true;
  }

  /// Ensure initialized before operations
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }

  // ==================== Secure Storage (Tokens, Sensitive Data) ====================

  /// Save auth token
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: AppConstants.tokenKey, value: token);
  }

  /// Get auth token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: AppConstants.tokenKey);
  }

  /// Delete auth token
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: AppConstants.tokenKey);
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Save user data securely
  Future<void> saveUser(User user) async {
    final userJson = jsonEncode(user.toJson());
    await _secureStorage.write(key: AppConstants.userKey, value: userJson);
  }

  /// Get stored user data
  Future<User?> getUser() async {
    final userJson = await _secureStorage.read(key: AppConstants.userKey);
    if (userJson == null || userJson.isEmpty) return null;

    try {
      final Map<String, dynamic> decoded = jsonDecode(userJson);
      return User.fromJson(decoded);
    } catch (e) {
      return null;
    }
  }

  /// Delete user data
  Future<void> deleteUser() async {
    await _secureStorage.delete(key: AppConstants.userKey);
  }

  /// Clear all secure storage
  Future<void> clearSecureStorage() async {
    await _secureStorage.deleteAll();
  }

  // ==================== App Settings (Non-Sensitive) ====================

  /// Save theme mode
  Future<void> saveThemeMode(ThemeModeSetting mode) async {
    await _ensureInitialized();
    await _settingsBox.put(AppConstants.themeKey, mode.index);
  }

  /// Get theme mode
  Future<ThemeModeSetting> getThemeMode() async {
    await _ensureInitialized();
    final index = _settingsBox.get(AppConstants.themeKey, defaultValue: 2);
    return ThemeModeSetting.values[index];
  }

  /// Save default image quality
  Future<void> saveDefaultQuality(int quality) async {
    await _ensureInitialized();
    await _settingsBox.put(AppConstants.defaultQualityKey, quality);
  }

  /// Get default image quality
  Future<int> getDefaultQuality() async {
    await _ensureInitialized();
    return _settingsBox.get(
      AppConstants.defaultQualityKey,
      defaultValue: AppConstants.highQuality,
    );
  }

  /// Save default output format
  Future<void> saveDefaultFormat(String format) async {
    await _ensureInitialized();
    await _settingsBox.put(AppConstants.defaultFormatKey, format);
  }

  /// Get default output format
  Future<String> getDefaultFormat() async {
    await _ensureInitialized();
    return _settingsBox.get(AppConstants.defaultFormatKey, defaultValue: 'pdf');
  }

  /// Save base URL
  Future<void> saveBaseUrl(String url) async {
    await _ensureInitialized();
    await _settingsBox.put(AppConstants.baseUrlKey, url);
  }

  /// Get base URL
  Future<String> getBaseUrl() async {
    await _ensureInitialized();
    return _settingsBox.get(
      AppConstants.baseUrlKey,
      defaultValue: AppConstants.defaultBaseUrl,
    );
  }

  /// Save onboarding completed status
  Future<void> saveOnboardingCompleted(bool completed) async {
    await _ensureInitialized();
    await _settingsBox.put(AppConstants.onboardingKey, completed);
  }

  /// Get onboarding completed status
  Future<bool> getOnboardingCompleted() async {
    await _ensureInitialized();
    return _settingsBox.get(AppConstants.onboardingKey, defaultValue: false);
  }

  /// Get all app settings
  Future<AppSettings> getAppSettings() async {
    await _ensureInitialized();

    return AppSettings(
      themeMode: await getThemeMode(),
      defaultImageQuality: await getDefaultQuality(),
      defaultOutputFormat: await getDefaultFormat(),
      baseUrl: await getBaseUrl(),
      onboardingCompleted: await getOnboardingCompleted(),
    );
  }

  /// Save all app settings
  Future<void> saveAppSettings(AppSettings settings) async {
    await _ensureInitialized();

    await saveThemeMode(settings.themeMode);
    await saveDefaultQuality(settings.defaultImageQuality);
    await saveDefaultFormat(settings.defaultOutputFormat);
    await saveBaseUrl(settings.baseUrl);
    await saveOnboardingCompleted(settings.onboardingCompleted);
  }

  // ==================== Generic Key-Value Storage ====================

  /// Save a string value
  Future<void> saveString(String key, String value) async {
    await _ensureInitialized();
    await _settingsBox.put(key, value);
  }

  /// Get a string value
  Future<String?> getString(String key) async {
    await _ensureInitialized();
    return _settingsBox.get(key);
  }

  /// Save an int value
  Future<void> saveInt(String key, int value) async {
    await _ensureInitialized();
    await _settingsBox.put(key, value);
  }

  /// Get an int value
  Future<int?> getInt(String key) async {
    await _ensureInitialized();
    return _settingsBox.get(key);
  }

  /// Save a bool value
  Future<void> saveBool(String key, bool value) async {
    await _ensureInitialized();
    await _settingsBox.put(key, value);
  }

  /// Get a bool value
  Future<bool?> getBool(String key) async {
    await _ensureInitialized();
    return _settingsBox.get(key);
  }

  /// Save a list of strings
  Future<void> saveStringList(String key, List<String> value) async {
    await _ensureInitialized();
    await _settingsBox.put(key, value);
  }

  /// Get a list of strings
  Future<List<String>> getStringList(String key) async {
    await _ensureInitialized();
    final value = _settingsBox.get(key);
    if (value == null) return [];
    return List<String>.from(value);
  }

  /// Remove a key
  Future<void> remove(String key) async {
    await _ensureInitialized();
    await _settingsBox.delete(key);
  }

  /// Check if key exists
  Future<bool> containsKey(String key) async {
    await _ensureInitialized();
    return _settingsBox.containsKey(key);
  }

  // ==================== Cache Management ====================

  /// Save cached data with timestamp
  Future<void> saveCache(String key, dynamic data) async {
    await _ensureInitialized();
    await _settingsBox.put('${key}_data', jsonEncode(data));
    await _settingsBox.put('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  /// Get cached data if not expired
  Future<dynamic> getCache(String key, {Duration? maxAge}) async {
    await _ensureInitialized();

    final timestamp = _settingsBox.get('${key}_timestamp');
    if (timestamp == null) return null;

    final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
    final maxAgeMs = (maxAge ?? AppConstants.cacheValidDuration).inMilliseconds;

    if (cacheAge > maxAgeMs) {
      // Cache expired
      await clearCache(key);
      return null;
    }

    final data = _settingsBox.get('${key}_data');
    if (data == null) return null;

    try {
      return jsonDecode(data);
    } catch (e) {
      return null;
    }
  }

  /// Clear specific cache
  Future<void> clearCache(String key) async {
    await _ensureInitialized();
    await _settingsBox.delete('${key}_data');
    await _settingsBox.delete('${key}_timestamp');
  }

  // ==================== Cleanup ====================

  /// Clear all local storage (non-secure)
  Future<void> clearLocalStorage() async {
    await _ensureInitialized();
    await _settingsBox.clear();
  }

  /// Clear everything (logout)
  Future<void> clearAll() async {
    await clearSecureStorage();
    await clearLocalStorage();
  }

  /// Close Hive boxes
  Future<void> dispose() async {
    if (_initialized) {
      await _settingsBox.close();
      _initialized = false;
    }
  }
}
