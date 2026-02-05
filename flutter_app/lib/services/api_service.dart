import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import 'storage_service.dart';

/// API Exception for handling HTTP errors
class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const ApiException({
    required this.message,
    this.code,
    this.statusCode,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() => 'ApiException: $message';
}

/// API Response wrapper
class ApiResponse<T> {
  final int? statusCode;
  final T? data;
  final String? message;

  const ApiResponse({
    this.statusCode,
    this.data,
    this.message,
  });
}

/// API Service - handles all HTTP requests to the backend
class ApiService {
  late final Dio _dio;
  final StorageService _storageService;
  String _baseUrl;

  String get baseUrl => _baseUrl;
  Dio get dio => _dio; // Expose dio for direct access

  ApiService({
    required StorageService storageService,
    String? baseUrl,
  })  : _storageService = storageService,
        _baseUrl = baseUrl ?? AppConstants.defaultBaseUrl {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: AppConstants.connectionTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      sendTimeout: AppConstants.uploadTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token if available
        final token = await _storageService.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        debugPrint('🌐 ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('✅ Response: ${response.statusCode}');
        return handler.next(response);
      },
      onError: (error, handler) {
        debugPrint('❌ Error: ${error.message}');
        return handler.next(error);
      },
    ));
  }

  /// Update base URL
  void updateBaseUrl(String newBaseUrl) {
    _baseUrl = newBaseUrl;
    _dio.options.baseUrl = newBaseUrl;
  }

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Upload a single file
  Future<Response> uploadFile(
    String path,
    File file, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        ...?additionalData,
      });

      return await _dio.post(
        path,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: AppConstants.uploadTimeout,
        ),
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Upload multiple files
  Future<Response> uploadMultipleFiles(
    String path,
    List<File> files, {
    String fieldName = 'files',
    Map<String, dynamic>? additionalData,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final formData = FormData();

      for (final file in files) {
        formData.files.add(MapEntry(
          fieldName,
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        ));
      }

      if (additionalData != null) {
        additionalData.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }

      return await _dio.post(
        path,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: AppConstants.uploadTimeout,
        ),
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Download a file
  Future<Response> downloadFile(
    String path,
    String savePath, {
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    try {
      return await _dio.download(
        path,
        savePath,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle Dio errors
  ApiException _handleDioError(DioException error) {
    String message;
    String? code;
    int? statusCode = error.response?.statusCode;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        code = 'CONNECTION_TIMEOUT';
        break;
      case DioExceptionType.sendTimeout:
        message = 'Request timeout. Please try again.';
        code = 'SEND_TIMEOUT';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Response timeout. Please try again.';
        code = 'RECEIVE_TIMEOUT';
        break;
      case DioExceptionType.badResponse:
        final data = error.response?.data;
        if (data is Map<String, dynamic>) {
          message = data['error']?['message'] ??
              data['message'] ??
              'Server error occurred';
          code = data['error']?['code'];
        } else {
          message = 'Server error occurred';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled';
        code = 'CANCELLED';
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection. Please check your network.';
        code = 'NO_CONNECTION';
        break;
      default:
        message = error.message ?? 'An unexpected error occurred';
        code = 'UNKNOWN_ERROR';
    }

    return ApiException(
      message: message,
      code: code,
      statusCode: statusCode,
    );
  }
}
