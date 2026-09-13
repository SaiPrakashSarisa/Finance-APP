import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_endpoints.dart';

/// Purpose: Dio HTTP API Client with JWT Bearer Token Interceptor & Robust Error Handling
/// Author: Antigravity AI

class ApiClient {
  late final Dio dio;

  static const List<String> fallbackUrls = [
    ApiEndpoints.localBaseUrl, // http://localhost:5001/api (iOS, Web, ADB reverse)
    'http://127.0.0.1:5001/api', // http://127.0.0.1:5001/api
    ApiEndpoints.physicalDeviceBaseUrl, // http://192.168.1.5:5001/api (Wi-Fi)
    ApiEndpoints.baseUrl, // http://10.0.2.2:5001/api (Android Emulator)
  ];

  static String _activeBaseUrl = ApiEndpoints.baseUrl;

  ApiClient({String? customBaseUrl}) {
    final initialUrl = customBaseUrl ??
        (kIsWeb ||
                defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS
            ? ApiEndpoints.localBaseUrl
            : _activeBaseUrl);

    dio = Dio(
      BaseOptions(
        baseUrl: initialUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        validateStatus: (status) => status != null && status < 500,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('jwt_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            options.headers['Cookie'] = 'token=$token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout) {
            for (final fallback in fallbackUrls) {
              if (fallback == dio.options.baseUrl) continue;
              try {
                final options = e.requestOptions;
                final cloneOptions = Options(
                  method: options.method,
                  headers: options.headers,
                  responseType: options.responseType,
                  contentType: options.contentType,
                  validateStatus: options.validateStatus,
                  receiveTimeout: options.receiveTimeout,
                  sendTimeout: options.sendTimeout,
                );
                final fullPath = options.path;
                final fallbackClient = Dio(BaseOptions(
                  baseUrl: fallback,
                  connectTimeout: const Duration(seconds: 5),
                  receiveTimeout: const Duration(seconds: 5),
                ));
                final response = await fallbackClient.request(
                  fullPath,
                  data: options.data,
                  queryParameters: options.queryParameters,
                  options: cloneOptions,
                );
                _activeBaseUrl = fallback;
                dio.options.baseUrl = fallback;
                return handler.resolve(response);
              } catch (_) {
                continue;
              }
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await dio.patch(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await dio.delete(path);
  }
}
