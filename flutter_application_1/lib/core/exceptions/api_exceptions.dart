class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (Code: $statusCode)';
}

class UnauthorizedException extends ApiException {
  UnauthorizedException() : super('Non autorisé - veuillez vous reconnecter', 401);
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message, 404);
}

class ValidationException extends ApiException {
  ValidationException(String message) : super(message, 400);
}
