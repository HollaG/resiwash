import 'package:dio/dio.dart';
import 'package:resiwash/core/errors/Failure.dart';
import 'package:resiwash/core/logging/logger.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Check if the response indicates an error
    if (response.statusCode != null && response.statusCode! >= 400) {
      appLog.e(
        '[api] Error response: ${response.statusCode} - ${response.data}',
      );

      // Extract custom error message from server response
      String errorMessage = _extractErrorMessage(response);

      // Throw a custom failure with the server's error message
      throw Failure(message: errorMessage);
    }

    // Continue with successful responses
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    appLog.e('[api] Network error: $err');

    // Handle network errors (no response from server)
    String errorMessage = _handleNetworkError(err);

    // Convert DioException to our custom Failure
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: Failure(message: errorMessage),
      ),
    );
  }

  String _extractErrorMessage(Response response) {
    try {
      // Handle your server's error response format:
      // {
      //   "status": "error",
      //   "error": {
      //     "message": "Your custom error message",
      //     "code": 404,
      //     "data": {...}
      //   }
      // }

      final data = response.data;

      if (data is Map<String, dynamic>) {
        // Check if it's your server's error format
        if (data['status'] == 'error' && data['error'] != null) {
          final error = data['error'];
          if (error is Map<String, dynamic> && error['message'] != null) {
            return error['message'].toString();
          }
          if (error is String) {
            return error;
          }
        }

        // Fallback: try other common error message fields
        if (data['error'] != null) {
          return data['error'].toString();
        }
        if (data['message'] != null) {
          return data['message'].toString();
        }
        if (data['errors'] != null && data['errors'] is List) {
          return (data['errors'] as List).join(', ');
        }
      }

      // Fallback to status code message
      return _getStatusCodeMessage(response.statusCode!);
    } catch (e) {
      appLog.w('[api] Failed to extract error message: $e');
      return _getStatusCodeMessage(response.statusCode ?? 500);
    }
  }

  String _handleNetworkError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Server response timeout. Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      case DioExceptionType.unknown:
        return 'An unexpected error occurred. Please try again.';
      default:
        return err.message ?? 'An error occurred. Please try again.';
    }
  }

  String _getStatusCodeMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please log in again.';
      case 403:
        return 'Access forbidden. You do not have permission.';
      case 404:
        return 'Resource not found.';
      case 422:
        return 'Validation error. Please check your input.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Bad gateway. Server is temporarily unavailable.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return 'An error occurred (Status: $statusCode). Please try again.';
    }
  }
}
