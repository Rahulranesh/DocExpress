import 'package:flutter/foundation.dart';

import '../core/exceptions/app_exception.dart';
import '../models/models.dart';
import '../services/local_auth_service.dart';
import '../services/offline_service_manager.dart';
import '../services/storage_service.dart';

/// Offline Auth Repository - replaces API-based auth repository
/// Uses local Hive storage instead of MongoDB
class OfflineAuthRepository {
  final LocalAuthService _authService;
  final StorageService _storageService;

  OfflineAuthRepository({
    LocalAuthService? authService,
    StorageService? storageService,
  })  : _authService = authService ?? offlineServices.authService,
        _storageService = storageService ?? StorageService();

  /// Register a new user (local only)
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    debugPrint(
        '🔐 [LOCAL STORAGE] Auth: Registering user locally (Hive) - $email');
    try {
      final localUser = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      debugPrint(
          '✅ [LOCAL STORAGE] Auth: User registered successfully - ${localUser.id}');

      final user = _convertToUser(localUser);

      // Save user to storage for UI compatibility
      await _storageService.saveUser(user);

      return AuthResponse(
        token: 'local_token_${localUser.id}', // Local token (not used for API)
        user: user,
      );
    } on AuthException catch (e) {
      throw AppException(message: e.message, statusCode: 400);
    }
  }

  /// Login with email and password (local only)
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    debugPrint('🔐 [LOCAL STORAGE] Auth: Logging in locally (Hive) - $email');
    try {
      final localUser = await _authService.login(
        email: email,
        password: password,
      );
      debugPrint('✅ [LOCAL STORAGE] Auth: Login successful - ${localUser.id}');

      final user = _convertToUser(localUser);

      // Save user to storage for UI compatibility
      await _storageService.saveUser(user);

      return AuthResponse(
        token: 'local_token_${localUser.id}',
        user: user,
      );
    } on AuthException catch (e) {
      throw AppException(message: e.message, statusCode: 401);
    }
  }

  /// Logout
  Future<void> logout() async {
    debugPrint('🔐 [LOCAL STORAGE] Auth: Logging out locally');
    await _authService.logout();
    await _storageService.deleteToken();
    await _storageService.deleteUser();
    debugPrint('✅ [LOCAL STORAGE] Auth: Logout complete');
  }

  /// Get current user profile
  Future<User> getCurrentUser() async {
    final localUser = await _authService.getCurrentUser();
    if (localUser == null) {
      throw const AppException(message: 'Not logged in', statusCode: 401);
    }
    return _convertToUser(localUser);
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _authService.isLoggedIn();
  }

  /// Update user profile
  Future<User> updateProfile({
    String? name,
    String? email,
  }) async {
    try {
      final localUser = await _authService.updateProfile(
        name: name,
        email: email,
      );
      if (localUser == null) {
        throw const AppException(message: 'Update failed', statusCode: 400);
      }

      final user = _convertToUser(localUser);
      await _storageService.saveUser(user);

      return user;
    } on AuthException catch (e) {
      throw AppException(message: e.message, statusCode: 400);
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } on AuthException catch (e) {
      throw AppException(message: e.message, statusCode: 400);
    }
  }

  /// Continue as guest (skip login)
  Future<AuthResponse> continueAsGuest() async {
    final localUser = await _authService.continueAsGuest();
    final user = _convertToUser(localUser);

    await _storageService.saveUser(user);

    return AuthResponse(
      token: 'guest_token_${localUser.id}',
      user: user,
    );
  }

  /// Get saved user from local storage
  Future<User?> getSavedUser() async {
    return await _storageService.getUser();
  }

  /// Delete account
  Future<void> deleteAccount() async {
    await _authService.deleteAccount();
    await _storageService.deleteToken();
    await _storageService.deleteUser();
  }

  /// Convert LocalUser to User model (for compatibility with existing UI)
  User _convertToUser(LocalUser localUser) {
    return User(
      id: localUser.id,
      name: localUser.name,
      email: localUser.email,
      createdAt: localUser.createdAt,
      updatedAt: localUser.updatedAt,
    );
  }
}
