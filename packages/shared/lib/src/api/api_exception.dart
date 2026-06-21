class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Network error occurred']);
  @override
  String toString() => 'NetworkException: $message';
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([String message = 'Unauthorized'])
      : super(statusCode: 401, message: message);
}

class NotFoundException extends ApiException {
  NotFoundException([String message = 'Resource not found'])
      : super(statusCode: 404, message: message);
}

class ValidationException extends ApiException {
  ValidationException([String message = 'Validation error', Map<String, dynamic>? errors])
      : super(statusCode: 422, message: message, errors: errors);
}
