/// Base exception class for auth-related errors
abstract class AuthException implements Exception {
  final String message;

  const AuthException({required this.message});

  @override
  String toString() => message;
}

/// Thrown when credentials are invalid
class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException({
    super.message = 'Invalid email or password',
  });
}

/// Thrown when user already exists
class UserAlreadyExistsException extends AuthException {
  const UserAlreadyExistsException({
    super.message = 'User with this email already exists',
  });
}

/// Thrown when token has expired
class TokenExpiredException extends AuthException {
  const TokenExpiredException({
    super.message = 'Session expired. Please login again',
  });
}

/// Thrown when user is not found
class UserNotFoundException extends AuthException {
  const UserNotFoundException({super.message = 'User not found'});
}

/// Thrown when network error occurs
class NetworkException extends AuthException {
  const NetworkException({
    super.message = 'Network error. Please check your connection',
  });
}

/// Thrown when server error occurs
class ServerException extends AuthException {
  const ServerException({
    super.message = 'Server error. Please try again later',
  });
}

/// Thrown when role selection is required
class RoleSelectionRequiredException extends AuthException {
  const RoleSelectionRequiredException({
    super.message = 'Role selection is required for new Google sign-in users',
  });
}

/// Thrown when Google sign-in fails
class GoogleSignInException extends AuthException {
  const GoogleSignInException({super.message = 'Google sign-in failed'});
}

/// Thrown when operation is not supported
class OperationNotSupportedException extends AuthException {
  const OperationNotSupportedException({
    super.message = 'This operation is not supported',
  });
}

/// Generic auth exception for unknown errors
class GenericAuthException extends AuthException {
  const GenericAuthException({
    super.message = 'An authentication error occurred',
  });
}
