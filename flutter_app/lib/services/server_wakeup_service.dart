import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';

/// Server Wake-up Service
/// 
/// Render free tier servers go to sleep after 15 minutes of inactivity.
/// This service wakes them up in the background so login/register is instant.
class ServerWakeupService {
  static final ServerWakeupService _instance = ServerWakeupService._internal();
  factory ServerWakeupService() => _instance;
  ServerWakeupService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 90),
    receiveTimeout: const Duration(seconds: 90),
  ));

  bool _isWakingUp = false;
  bool _authServerAwake = false;
  bool _conversionServerAwake = false;

  /// Wake up both backend servers
  Future<void> wakeUpServers() async {
    if (_isWakingUp) {
      debugPrint('🔄 [WAKEUP] Already waking up servers...');
      return;
    }

    _isWakingUp = true;
    debugPrint('⏰ [WAKEUP] Starting server wake-up process...');

    // Wake up both servers in parallel
    await Future.wait([
      _wakeUpAuthServer(),
      _wakeUpConversionServer(),
    ]);

    _isWakingUp = false;
    debugPrint('✅ [WAKEUP] Server wake-up process complete');
  }

  /// Wake up authentication server (MongoDB backend)
  Future<void> _wakeUpAuthServer() async {
    if (_authServerAwake) {
      debugPrint('✓ [WAKEUP] Auth server already awake');
      return;
    }

    try {
      debugPrint('🌐 [WAKEUP] Pinging auth server...');
      final startTime = DateTime.now();

      // Simple health check endpoint - doesn't require authentication
      final response = await _dio.get(
        '${AppConstants.defaultBaseUrl}/health',
        options: Options(
          validateStatus: (status) => true, // Accept any status
        ),
      ).timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          debugPrint('⏱️ [WAKEUP] Auth server timeout (still waking up)');
          return Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 408,
          );
        },
      );

      final duration = DateTime.now().difference(startTime);
      
      if (response.statusCode != null && response.statusCode! < 500) {
        _authServerAwake = true;
        debugPrint('✅ [WAKEUP] Auth server awake! (${duration.inSeconds}s)');
      } else {
        debugPrint('⚠️ [WAKEUP] Auth server responded with ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ [WAKEUP] Auth server wake-up error: $e');
      // Don't throw - we'll try again on actual login
    }
  }

  /// Wake up conversion server (document processing backend)
  Future<void> _wakeUpConversionServer() async {
    if (_conversionServerAwake) {
      debugPrint('✓ [WAKEUP] Conversion server already awake');
      return;
    }

    try {
      debugPrint('🌐 [WAKEUP] Pinging conversion server...');
      final startTime = DateTime.now();

      // Simple health check endpoint
      final response = await _dio.get(
        '${AppConstants.conversionBaseUrl}/health',
        options: Options(
          validateStatus: (status) => true, // Accept any status
        ),
      ).timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          debugPrint('⏱️ [WAKEUP] Conversion server timeout (still waking up)');
          return Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 408,
          );
        },
      );

      final duration = DateTime.now().difference(startTime);
      
      if (response.statusCode != null && response.statusCode! < 500) {
        _conversionServerAwake = true;
        debugPrint('✅ [WAKEUP] Conversion server awake! (${duration.inSeconds}s)');
      } else {
        debugPrint('⚠️ [WAKEUP] Conversion server responded with ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ [WAKEUP] Conversion server wake-up error: $e');
      // Don't throw - we'll try again on actual operation
    }
  }

  /// Check if auth server is awake
  bool get isAuthServerAwake => _authServerAwake;

  /// Check if conversion server is awake
  bool get isConversionServerAwake => _conversionServerAwake;

  /// Reset wake-up status (for testing)
  void reset() {
    _authServerAwake = false;
    _conversionServerAwake = false;
    _isWakingUp = false;
  }

  /// Wake up auth server only (for login/register screens)
  Future<void> wakeUpAuthServerOnly() async {
    if (_authServerAwake || _isWakingUp) {
      return;
    }
    
    _isWakingUp = true;
    await _wakeUpAuthServer();
    _isWakingUp = false;
  }
}
