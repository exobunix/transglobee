import 'package:dio/dio.dart';

class ErrorHandler {
  static String handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return "Connection Timeout";
        case DioExceptionType.sendTimeout:
          return "Send Timeout";
        case DioExceptionType.receiveTimeout:
          return "Receive Timeout";
        case DioExceptionType.badResponse:
          final data = error.response?.data;
          if (data != null &&
              data is Map<String, dynamic> &&
              data['message'] != null) {
            return data['message'].toString();
          }
          return "Bad Response: ${error.response?.statusCode}";
        case DioExceptionType.cancel:
          return "Request Cancelled";
        case DioExceptionType.connectionError:
          return "Connection Error. Please check your internet connection.";
        default:
          return "Something went wrong";
      }
    }
    return error.toString();
  }
}
