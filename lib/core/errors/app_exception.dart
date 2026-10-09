sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Network error. Check your connection.']);
}

class AuthAppException extends AppException {
  const AuthAppException([super.message = 'Authentication error.']);
}

class PermissionException extends AppException {
  const PermissionException(
      [super.message = 'You do not have permission to perform this action.']);
}

class ValidationException extends AppException {
  const ValidationException([super.message = 'Validation error.']);
}

class NotFoundAppException extends AppException {
  const NotFoundAppException([super.message = 'The requested item was not found.']);
}

class ServerException extends AppException {
  const ServerException([super.message = 'An unexpected server error occurred.']);
}

class AppStorageException extends AppException {
  const AppStorageException([super.message = 'Storage operation failed.']);
}
