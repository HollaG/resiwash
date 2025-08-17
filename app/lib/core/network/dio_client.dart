import 'package:dio/dio.dart';
import 'package:resiwash/core/network/error_interceptor.dart';

// final options = CacheOptions(
//   store: MemCacheStore(),
//   hitCacheOnNetworkFailure: true,
//   maxStale: const Duration(days: 7),
//   priority: CachePriority.normal,
// );

class DioClient {
  static Dio instance() {
    final dio = Dio(
      BaseOptions(
        baseUrl:
            "http://192.168.1.10:3000/api/v2", //Jsonplaceholder is a great place for getting dummy data.
        validateStatus: (status) {
          // Allow all status codes so the interceptor can handle them
          return true;
        },
      ),
    );

    // Add the error interceptor to handle custom error messages
    dio.interceptors.add(ErrorInterceptor());

    //Optional cashing,
    // dio.interceptors.add(DioCacheInterceptor(options: options));
    return dio;
  }
}
