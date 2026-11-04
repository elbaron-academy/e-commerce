import 'package:dio/dio.dart';

/// An API error. The backend answers `{"detail": "...", "code": "...", "field": "..."}`
/// with the message already translated, so it can be shown as-is.
class ApiException implements Exception {
  const ApiException({required this.message, this.code, this.field, this.statusCode, this.data});

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    if (response == null) {
      return const ApiException(message: '', code: 'network');
    }
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ApiException(
        message: (data['detail'] ?? '').toString(),
        code: data['code']?.toString(),
        field: data['field']?.toString(),
        statusCode: response.statusCode,
        data: data,
      );
    }
    return ApiException(message: '', statusCode: response.statusCode);
  }

  final String message;
  final String? code;
  final String? field;
  final int? statusCode;
  final Map<String, dynamic>? data;

  bool get isNetwork => code == 'network';

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
