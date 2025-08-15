import 'package:dio/dio.dart';

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
  }
  Dio get client => _dio;
}
