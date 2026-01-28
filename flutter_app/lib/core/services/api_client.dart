import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/env_config.dart';
import '../config/app_constants.dart';

/// API client using Dio
class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  ApiClient(this._secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(_AuthInterceptor(_secureStorage, _dio));
    _dio.interceptors.add(_LoggingInterceptor());
  }

  Dio get dio => _dio;

  // GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  // POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  // PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  // PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.patch<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  // DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  // Upload file
  Future<Response<T>> uploadFile<T>(
    String path,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? data,
    void Function(int, int)? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
      if (data != null) ...data,
    });

    return _dio.post<T>(
      path,
      data: formData,
      onSendProgress: onSendProgress,
    );
  }
}

/// Auth interceptor for adding JWT token and refreshing
class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;
  final Dio _dio;

  _AuthInterceptor(this._secureStorage, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _secureStorage.read(key: AppConstants.accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try to refresh token
      final refreshToken = await _secureStorage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken != null) {
        try {
          final response = await _dio.post(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
          );

          final data = response.data['data'] ?? response.data;
          final newToken = data['accessToken'] ?? data['token'];
          final newRefreshToken = data['refreshToken'];

          await _secureStorage.write(key: AppConstants.accessTokenKey, value: newToken);
          await _secureStorage.write(key: AppConstants.refreshTokenKey, value: newRefreshToken);

          // Retry the original request
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await _dio.fetch(err.requestOptions);
          return handler.resolve(retryResponse);
        } catch (e) {
          // Refresh failed - logout
          await _secureStorage.delete(key: AppConstants.accessTokenKey);
          await _secureStorage.delete(key: AppConstants.refreshTokenKey);
        }
      }
    }
    handler.next(err);
  }
}

/// Logging interceptor for debugging
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('✖ ${err.response?.statusCode} ${err.requestOptions.uri}');
    handler.next(err);
  }
}

/// API client provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return ApiClient(secureStorage);
});

/// Secure storage provider (if not already defined)
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});
