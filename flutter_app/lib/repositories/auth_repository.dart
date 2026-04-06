import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/constants/app_constants.dart';
import '../core/exceptions/app_exception.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

/// Auth Repository - MongoDB backend authentication
class AuthRepository {
  final ApiService _apiService;
  final StorageService _storageService;

  static const Duration _authRequestTimeout = Duration(seconds: 30);

  AuthRepository({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  /// Register a new user
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    debugPrint('🔐 [API] Auth: Registering user - $email');
    try {
      final response = await _apiService.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
        options: Options(
          receiveTimeout: _authRequestTimeout,
          sendTimeout: _authRequestTimeout,
        ),
      );

      if (response.data == null) {
        throw AppException(message: 'Registration failed');
      }

      final authResponse = AuthResponse.fromJson(response.data);

      // Save token and user
      await _storageService.saveToken(authResponse.token);
      await _storageService.saveUser(authResponse.user);

      debugPrint('✅ [API] Auth: User registered successfully');
      return authResponse;
    } on AppException catch (e) {
      debugPrint('❌ [API] Auth: Registration failed with AppException');
      debugPrint('❌ [API] Auth: Error message - ${e.message}');
      debugPrint('❌ [API] Auth: Error statusCode - ${e.statusCode}');
      rethrow; // Re-throw as-is to preserve the message
    } catch (e) {
      debugPrint('❌ [API] Auth: Registration failed - $e');
      debugPrint('❌ [API] Auth: Error type - ${e.runtimeType}');
      
      // If it's already an AppException, just rethrow
      if (e is AppException) {
        rethrow;
      }
      
      throw AppException(message: e.toString());
    }
  }

  /// Login with email and password
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    debugPrint('🔐 [API] Auth: Logging in - $email');
    try {
      final response = await _apiService.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(
          receiveTimeout: _authRequestTimeout,
          sendTimeout: _authRequestTimeout,
        ),
      );

      if (response.data == null) {
        throw AppException(message: 'Login failed');
      }

      final authResponse = AuthResponse.fromJson(response.data);

      // Save token and user
      await _storageService.saveToken(authResponse.token);
      await _storageService.saveUser(authResponse.user);

      debugPrint('✅ [API] Auth: Login successful');
      return authResponse;
    } catch (e) {
      debugPrint('❌ [API] Auth: Login failed - $e');
      if (e is AppException) rethrow;
      throw AppException(message: e.toString());
    }
  }

  /// Login with Google account
  Future<AuthResponse> loginWithGoogle() async {
    debugPrint('🔐 [API] Auth: Logging in with Google');
    try {
      final webClientId = AppConstants.googleWebClientId.trim();
      final iosClientId = AppConstants.googleIosClientId.trim();

      if (Platform.isIOS && iosClientId.isEmpty) {
        throw AppException(
          message:
              'Google sign-in is not configured for iOS. Pass GOOGLE_IOS_CLIENT_ID and add REVERSED_CLIENT_ID URL scheme in Info.plist.',
        );
      }

      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        clientId: Platform.isIOS && iosClientId.isNotEmpty
            ? iosClientId
            : null,
        serverClientId: webClientId.isNotEmpty
            ? webClientId
            : null,
      );

      // Sign out first to show account picker
      try {
        await googleSignIn.signOut();
      } catch (_) {}
      final account = await googleSignIn.signIn();
      if (account == null) {
        throw AppException(message: 'Google sign-in cancelled');
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw AppException(
          message:
              'Google sign-in failed: missing ID token. Set GOOGLE_WEB_CLIENT_ID in app build.',
        );
      }

      final response = await _apiService.post(
        '/auth/google',
        data: {
          'idToken': idToken,
        },
        options: Options(
          receiveTimeout: _authRequestTimeout,
          sendTimeout: _authRequestTimeout,
        ),
      );

      if (response.data == null) {
        throw AppException(message: 'Google login failed');
      }

      final authResponse = AuthResponse.fromJson(response.data);

      await _storageService.saveToken(authResponse.token);
      await _storageService.saveUser(authResponse.user);

      debugPrint('✅ [API] Auth: Google login successful');
      return authResponse;
    } on PlatformException catch (e) {
      debugPrint('❌ [API] Auth: Google platform exception - ${e.code}: ${e.message}');
      throw AppException(message: _mapGoogleSignInPlatformError(e));
    } catch (e) {
      debugPrint('❌ [API] Auth: Google login failed - $e');
      if (e is AppException) rethrow;
      throw AppException(message: e.toString());
    }
  }

  String _mapGoogleSignInPlatformError(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();

    if (code.contains('sign_in_canceled') || message.contains('canceled')) {
      return 'Google sign-in cancelled';
    }

    if (code.contains('network_error') || message.contains('network')) {
      return 'Google sign-in failed due to network issues. Please check your internet connection.';
    }

    if (code.contains('sign_in_failed') ||
        message.contains('12500') ||
        message.contains('12501') ||
        message.contains('12502') ||
        message.contains('10') ||
        message.contains('developer_error')) {
      return 'Google sign-in configuration error. Please verify SHA fingerprints, package name, and OAuth client IDs.';
    }

    if (message.contains('missing support for the following url schemes') ||
        message.contains('reversed_client_id')) {
      return 'iOS Google sign-in setup is incomplete. Add REVERSED_CLIENT_ID URL scheme in Info.plist and set GOOGLE_IOS_CLIENT_ID.';
    }

    return 'Google sign-in failed on this device. Please try again.';
  }

  /// Logout
  Future<void> logout() async {
    debugPrint('🚪 [API] Auth: Logging out');
    await _storageService.deleteToken();
    await _storageService.deleteUser();
  }

  /// Get locally stored user without making a network request
  Future<User?> getStoredUser() async {
    return _storageService.getUser();
  }

  /// Get current user from API
  Future<User> getCurrentUser() async {
    debugPrint('👤 [API] Auth: Getting current user');
    try {
      final response = await _apiService
          .get('/auth/me')
          .timeout(const Duration(seconds: 8));

      if (response.data == null) {
        throw AppException(message: 'Failed to get user data');
      }

      final data = response.data['data'] ?? response.data;
      final user = User.fromJson(data['user']);

      // Update stored user
      await _storageService.saveUser(user);

      return user;
    } catch (e) {
      debugPrint('❌ [API] Auth: Failed to get user - $e');
      // Try to get from local storage
      final localUser = await _storageService.getUser();
      if (localUser != null) {
        return localUser;
      }
      throw AppException(message: 'Not authenticated');
    }
  }

  /// Update user profile
  Future<User> updateProfile({String? name, String? email}) async {
    debugPrint('📝 [API] Auth: Updating profile');
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;

      final response = await _apiService.put('/auth/profile', data: data);

      if (response.data == null) {
        throw AppException(message: 'Failed to update profile');
      }

      final responseData = response.data['data'] ?? response.data;
      final user = User.fromJson(responseData['user']);

      // Update stored user
      await _storageService.saveUser(user);

      debugPrint('✅ [API] Auth: Profile updated');
      return user;
    } catch (e) {
      debugPrint('❌ [API] Auth: Failed to update profile - $e');
      if (e is AppException) rethrow;
      throw AppException(message: e.toString());
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    debugPrint('🔑 [API] Auth: Changing password');
    try {
      await _apiService.put(
        '/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      debugPrint('✅ [API] Auth: Password changed');
    } catch (e) {
      debugPrint('❌ [API] Auth: Failed to change password - $e');
      if (e is AppException) rethrow;
      throw AppException(message: e.toString());
    }
  }

  /// Delete account
  Future<void> deleteAccount({required String password}) async {
    debugPrint('🗑️ [API] Auth: Deleting account');
    try {
      await _apiService.delete(
        '/auth/account',
        data: {
          'password': password,
        },
      );

      // Clear local data
      await _storageService.deleteToken();
      await _storageService.deleteUser();

      debugPrint('✅ [API] Auth: Account deleted');
    } catch (e) {
      debugPrint('❌ [API] Auth: Failed to delete account - $e');
      if (e is AppException) rethrow;
      throw AppException(message: e.toString());
    }
  }

  /// Forgot password (email + new password)
  Future<void> forgotPassword({
    required String email,
    required String newPassword,
  }) async {
    debugPrint('🔐 [API] Auth: Forgot password for $email');
    try {
      await _apiService.post(
        '/auth/forgot-password',
        data: {
          'email': email,
          'newPassword': newPassword,
        },
      );
      debugPrint('✅ [API] Auth: Password reset successful');
    } catch (e) {
      debugPrint('❌ [API] Auth: Forgot password failed - $e');
      if (e is AppException) rethrow;
      throw AppException(message: e.toString());
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _storageService.getToken();
    return token != null && token.isNotEmpty;
  }

  /// Rate the app (requires authentication)
  Future<void> rateApp(int rating) async {
    if (rating < 1 || rating > 5) {
      throw AppException(message: 'Rating must be between 1 and 5');
    }

    debugPrint('⭐ [API] Auth: Submitting app rating - $rating stars');
    try {
      await _apiService.post(
        '/auth/rate-app',
        data: {
          'rating': rating,
        },
      );
      debugPrint('✅ [API] Auth: Rating submitted successfully');
    } catch (e) {
      debugPrint('❌ [API] Auth: Failed to submit rating - $e');
      if (e is AppException) rethrow;
      throw AppException(message: e.toString());
    }
  }

  /// Get average app rating
  Future<Map<String, dynamic>> getAverageRating() async {
    debugPrint('⭐ [API] Auth: Fetching average app rating');
    try {
      final response = await _apiService.get('/auth/average-rating');

      if (response.data == null || response.data['data'] == null) {
        return {
          'averageRating': 0.0,
          'totalRatings': 0,
        };
      }

      debugPrint('✅ [API] Auth: Average rating fetched successfully');
      return {
        'averageRating':
            (response.data['data']['averageRating'] as num).toDouble(),
        'totalRatings': response.data['data']['totalRatings'] as int,
      };
    } catch (e) {
      debugPrint('❌ [API] Auth: Failed to fetch average rating - $e');
      return {
        'averageRating': 0.0,
        'totalRatings': 0,
      };
    }
  }
}
