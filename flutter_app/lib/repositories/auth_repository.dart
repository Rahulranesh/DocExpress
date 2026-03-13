import 'package:flutter/foundation.dart';

import '../core/exceptions/app_exception.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

/// Auth Repository - MongoDB backend authentication
class AuthRepository {
  final ApiService _apiService;
  final StorageService _storageService;

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
    } catch (e) {
      debugPrint('❌ [API] Auth: Registration failed - $e');
      if (e is AppException) rethrow;
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

  /// Logout
  Future<void> logout() async {
    debugPrint('🚪 [API] Auth: Logging out');
    await _storageService.deleteToken();
    await _storageService.deleteUser();
  }

  /// Get current user from API
  Future<User> getCurrentUser() async {
    debugPrint('👤 [API] Auth: Getting current user');
    try {
      final response = await _apiService.get('/auth/me');

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
