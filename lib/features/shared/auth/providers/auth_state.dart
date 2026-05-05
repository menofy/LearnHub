import 'package:learnhub/domain/entities/app_user.dart';

/// Base auth state
abstract class AuthState {
  const AuthState();
}

/// Initial auth state
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading auth state
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Success auth state - user is authenticated
class AuthSuccess extends AuthState {
  final AppUser user;

  const AuthSuccess({required this.user});

  @override
  String toString() => 'AuthSuccess(user: $user)';
}

/// Unauthenticated state
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Failure auth state
class AuthFailure extends AuthState {
  final String message;
  final Exception? exception;

  const AuthFailure({required this.message, this.exception});

  @override
  String toString() => 'AuthFailure(message: $message)';
}

/// Role selection required state - for new Google sign-in users
class AuthRoleSelectionRequired extends AuthState {
  final String email;
  final String? name;

  const AuthRoleSelectionRequired({required this.email, this.name});

  @override
  String toString() => 'AuthRoleSelectionRequired(email: $email)';
}

/// Email verification required state
class AuthEmailVerificationRequired extends AuthState {
  final String email;

  const AuthEmailVerificationRequired({required this.email});

  @override
  String toString() => 'AuthEmailVerificationRequired(email: $email)';
}
