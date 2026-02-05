import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';

/// Local Auth Service - handles authentication locally without backend
class LocalAuthService {
  static const _uuid = Uuid();
  static const String _usersBoxName = 'local_users';
  static const String _currentUserKey = 'current_user_id';
  
  final FlutterSecureStorage _secureStorage;
  Box<Map>? _usersBox;
  bool _initialized = false;

  LocalAuthService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  /// Initialize the auth service
  Future<void> init() async {
    if (_initialized) return;
    
    _usersBox = await Hive.openBox<Map>(_usersBoxName);
    _initialized = true;
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }

  /// Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Register a new user
  Future<LocalUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _ensureInitialized();

    // Check if email already exists
    final existingUser = await _findUserByEmail(email);
    if (existingUser != null) {
      throw AuthException('Email already registered');
    }

    final userId = _uuid.v4();
    final now = DateTime.now();

    final user = LocalUser(
      id: userId,
      name: name,
      email: email.toLowerCase(),
      passwordHash: _hashPassword(password),
      createdAt: now,
      updatedAt: now,
    );

    await _usersBox!.put(userId, user.toMap());
    
    // Auto-login after registration
    await _setCurrentUser(userId);
    
    return user;
  }

  /// Login with email and password
  Future<LocalUser> login({
    required String email,
    required String password,
  }) async {
    await _ensureInitialized();

    final user = await _findUserByEmail(email.toLowerCase());
    if (user == null) {
      throw AuthException('Invalid email or password');
    }

    final passwordHash = _hashPassword(password);
    if (user.passwordHash != passwordHash) {
      throw AuthException('Invalid email or password');
    }

    // Set current user
    await _setCurrentUser(user.id);

    return user;
  }

  /// Logout current user
  Future<void> logout() async {
    await _secureStorage.delete(key: _currentUserKey);
  }

  /// Get current logged in user
  Future<LocalUser?> getCurrentUser() async {
    await _ensureInitialized();

    final userId = await _secureStorage.read(key: _currentUserKey);
    if (userId == null) return null;

    final map = _usersBox!.get(userId);
    if (map == null) return null;

    return LocalUser.fromMap(Map<String, dynamic>.from(map));
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  /// Update user profile
  Future<LocalUser?> updateProfile({
    String? name,
    String? email,
  }) async {
    await _ensureInitialized();

    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      throw AuthException('Not logged in');
    }

    // Check email uniqueness if changing
    if (email != null && email.toLowerCase() != currentUser.email) {
      final existingUser = await _findUserByEmail(email.toLowerCase());
      if (existingUser != null) {
        throw AuthException('Email already in use');
      }
    }

    final updatedUser = currentUser.copyWith(
      name: name,
      email: email?.toLowerCase(),
      updatedAt: DateTime.now(),
    );

    await _usersBox!.put(currentUser.id, updatedUser.toMap());
    return updatedUser;
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _ensureInitialized();

    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      throw AuthException('Not logged in');
    }

    // Verify current password
    if (currentUser.passwordHash != _hashPassword(currentPassword)) {
      throw AuthException('Current password is incorrect');
    }

    // Update password
    final updatedUser = currentUser.copyWith(
      passwordHash: _hashPassword(newPassword),
      updatedAt: DateTime.now(),
    );

    await _usersBox!.put(currentUser.id, updatedUser.toMap());
  }

  /// Delete account
  Future<void> deleteAccount() async {
    await _ensureInitialized();

    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      throw AuthException('Not logged in');
    }

    await _usersBox!.delete(currentUser.id);
    await logout();
  }

  /// Find user by email
  Future<LocalUser?> _findUserByEmail(String email) async {
    for (final map in _usersBox!.values) {
      final user = LocalUser.fromMap(Map<String, dynamic>.from(map));
      if (user.email == email.toLowerCase()) {
        return user;
      }
    }
    return null;
  }

  /// Set current user ID in secure storage
  Future<void> _setCurrentUser(String userId) async {
    await _secureStorage.write(key: _currentUserKey, value: userId);
  }

  /// Skip login (for guest mode)
  Future<LocalUser> continueAsGuest() async {
    await _ensureInitialized();

    // Create or get guest user
    const guestEmail = 'guest@docxpress.local';
    var guestUser = await _findUserByEmail(guestEmail);

    if (guestUser == null) {
      final userId = 'guest_${_uuid.v4()}';
      final now = DateTime.now();

      guestUser = LocalUser(
        id: userId,
        name: 'Guest User',
        email: guestEmail,
        passwordHash: '',
        isGuest: true,
        createdAt: now,
        updatedAt: now,
      );

      await _usersBox!.put(userId, guestUser.toMap());
    }

    await _setCurrentUser(guestUser.id);
    return guestUser;
  }
}

/// Local user model
class LocalUser {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final bool isGuest;
  final String? avatarPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  LocalUser({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.isGuest = false,
    this.avatarPath,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'passwordHash': passwordHash,
      'isGuest': isGuest,
      'avatarPath': avatarPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LocalUser.fromMap(Map<String, dynamic> map) {
    return LocalUser(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      passwordHash: map['passwordHash'] as String,
      isGuest: map['isGuest'] as bool? ?? false,
      avatarPath: map['avatarPath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  LocalUser copyWith({
    String? id,
    String? name,
    String? email,
    String? passwordHash,
    bool? isGuest,
    String? avatarPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocalUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      isGuest: isGuest ?? this.isGuest,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get initials from name
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

/// Auth exception
class AuthException implements Exception {
  final String message;
  
  AuthException(this.message);

  @override
  String toString() => message;
}
