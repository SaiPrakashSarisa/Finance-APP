import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../constants/api_endpoints.dart';

/// Purpose: Production Dio HTTP API Client with JWT Bearer Token, Idempotency Header & Timeout Safety
/// Author: Antigravity AI

class ApiClient {
  late final Dio dio;
  static final _uuid = const Uuid();

  static List<String> get fallbackUrls => [
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
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
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

          // Attach X-Idempotency-Key header automatically for state-mutating HTTP methods if not provided
          final method = options.method.toUpperCase();
          if (['POST', 'PUT', 'PATCH', 'DELETE'].contains(method)) {
            if (!options.headers.containsKey('X-Idempotency-Key')) {
              options.headers['X-Idempotency-Key'] = _uuid.v4();
            }
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // CRITICAL BUGFIX: Fallback host retry is restricted to READ-ONLY (GET, HEAD) requests.
          // State-mutating requests (POST, PUT, PATCH) must NEVER be automatically re-transmitted on connection errors.
          final isReadMethod = ['GET', 'HEAD'].contains(e.requestOptions.method.toUpperCase());

          if (isReadMethod &&
              (e.type == DioExceptionType.connectionError ||
               e.type == DioExceptionType.connectionTimeout)) {
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
                  connectTimeout: const Duration(seconds: 8),
                  receiveTimeout: const Duration(seconds: 8),
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

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? headers}) async {
    return await dio.post(
      path,
      data: data,
      options: headers != null ? Options(headers: headers) : null,
    );
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? headers}) async {
    return await dio.put(
      path,
      data: data,
      options: headers != null ? Options(headers: headers) : null,
    );
  }

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? headers}) async {
    return await dio.patch(
      path,
      data: data,
      options: headers != null ? Options(headers: headers) : null,
    );
  }

  Future<Response> delete(String path, {Map<String, dynamic>? headers}) async {
    return await dio.delete(
      path,
      options: headers != null ? Options(headers: headers) : null,
    );
  }
}
