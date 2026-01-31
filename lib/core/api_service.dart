import 'package:dio/dio.dart';
import 'constants.dart';
import 'storage_service.dart';

import 'package:flutter/foundation.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late Dio _dio;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(
          seconds: 10,
        ), // Reduced for faster feedback
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Logging Interceptor for Debugging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode) {
            print('🌐 API Request: [${options.method}] ${options.uri}');
          }
          return handler.next(options);
        },
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, handler) async {
          // Retry on DNS lookup failures
          if (error.type == DioExceptionType.connectionError ||
              error.message?.contains('Failed host lookup') == true) {
            // Wait a bit and retry once
            await Future.delayed(const Duration(seconds: 2));
            try {
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
          return handler.next(error);
        },
      ),
    );

    // 401 Error Handler - Clear auth data on unauthorized responses
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Token expired or invalid - clear auth data
            await storageService.remove(AppConstants.authTokenKey);
            await storageService.remove(AppConstants.userEmailKey);
            await storageService.remove(AppConstants.userNameKey);
            await storageService.remove(AppConstants.userIdKey);
            await storageService.remove(AppConstants.userRoleKey);
          }
          return handler.next(e);
        },
      ),
    );

    // Auth Header Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = storageService.getString(AppConstants.authTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          return handler.next(e);
        },
      ),
    );
  }

  Dio get client => _dio;

  Future<Map<String, dynamic>> getAppVersion() async {
    try {
      final response = await _dio.get('/app/version');
      return response.data;
    } catch (e) {
      // In case of error (e.g. offline), we might want to let them pass or retry
      // For now, rethrow or return empty to handle in UI
      rethrow;
    }
  }
}
