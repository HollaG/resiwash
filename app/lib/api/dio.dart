import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:resiwash/core/logging/logger.dart';

class DioClient {
  late final Dio _dio;
  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.example.com',
        connectTimeout: Duration(milliseconds: 5000), // 5 seconds
        receiveTimeout: Duration(milliseconds: 3000), // 3 seconds
      ),
    );
    // Add interceptors for logging and error handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('Request: ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('Response: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print('Error: ${e.message}');
          return handler.next(e);
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        request: !kReleaseMode,
        requestHeader: !kReleaseMode,
        requestBody: !kReleaseMode,
        responseHeader: false,
        responseBody: !kReleaseMode,
        error: true,
        logPrint: (obj) => log.d(obj),
      ),
    );
  }
  Dio get client => _dio;
}
