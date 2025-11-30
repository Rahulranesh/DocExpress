import '../core/constants/app_constants.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

/// Auth Repository - handles authentication operations
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
    final response = await _apiService.post(
      ApiEndpoints.register,
      data: RegisterRequest(
        name: name,
        email: email,
        password: password,
      ).toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final authResponse = AuthResponse.fromJson(response.data);

      // Save token and user
      await _storageService.saveToken(authResponse.token);
      await _storageService.saveUser(authResponse.user);

      return authResponse;
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Registration failed',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Login with email and password
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.login,
      data: LoginRequest(
        email: email,
        password: password,
      ).toJson(),
    );

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(response.data);

      // Save token and user
      await _storageService.saveToken(authResponse.token);
      await _storageService.saveUser(authResponse.user);

      return authResponse;
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Login failed',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Get current user profile
  Future<User> getCurrentUser() async {
    final response = await _apiService.get(ApiEndpoints.profile);

    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      final user = User.fromJson(data['user'] ?? data);

      // Update stored user
      await _storageService.saveUser(user);

      return user;
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to get profile',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Update user profile
  Future<User> updateProfile({String? name}) async {
    final response = await _apiService.patch(
      ApiEndpoints.profile,
      data: {
        if (name != null) 'name': name,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      final user = User.fromJson(data['user'] ?? data);

      // Update stored user
      await _storageService.saveUser(user);

      return user;
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to update profile',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );

    if (response.statusCode == 200) {
      // If new token is returned, update it
      final data = response.data['data'];
      if (data != null && data['token'] != null) {
        await _storageService.saveToken(data['token']);
      }
      return;
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to change password',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Refresh token
  Future<String> refreshToken() async {
    final response = await _apiService.post(ApiEndpoints.refreshToken);

    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      final token = data['token'] as String;

      await _storageService.saveToken(token);

      return token;
    }

    throw ApiException(
      message: response.data?['error']?['message'] ?? 'Failed to refresh token',
      code: response.data?['error']?['code'],
      statusCode: response.statusCode,
    );
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      // Call delete account endpoint
      await _apiService.delete(ApiEndpoints.deleteAccount);
    } catch (_) {
      // Continue with local cleanup even if API call fails
    }

    // Clear all stored data
    await _storageService.deleteToken();
    await _storageService.deleteUser();
  }

  /// Logout
  Future<void> logout() async {
    try {
      // Try to call logout endpoint (optional)
      await _apiService.post(ApiEndpoints.logout);
    } catch (_) {
      // Ignore errors - we'll clear local storage anyway
    }

    // Clear all stored data
    await _storageService.deleteToken();
    await _storageService.deleteUser();
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _storageService.isAuthenticated();
  }

  /// Get stored user (offline)
  Future<User?> getStoredUser() async {
    return await _storageService.getUser();
  }

  /// Get stored token
  Future<String?> getToken() async {
    return await _storageService.getToken();
  }

  /// Validate token by fetching current user
  Future<bool> validateToken() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return false;

      await getCurrentUser();
      return true;
    } catch (_) {
      return false;
    }
  }
}
