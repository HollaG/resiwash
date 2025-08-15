import 'package:dio/dio.dart';

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
            "https://resiwash.marcussoh.com/api/v1", //Jsonplaceholder is a great place for getting dummy data.
      ),
    );

    //Optional cashing,
    // dio.interceptors.add(DioCacheInterceptor(options: options));
    return dio;
  }
}
