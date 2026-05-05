import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';

import '../../domain/entities/app_user.dart';

/// Auth guard for protecting routes based on authentication status and user roles
class AuthGuard {
  final AuthProvider authProvider;

  AuthGuard({required this.authProvider});

  /// Check if the startup/auth session is still being resolved.
  bool isResolvingSession() {
    return authProvider.isSessionBootstrapping;
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return !authProvider.isSessionBootstrapping && authProvider.isAuthenticated;
  }

  /// Check if user is not authenticated
  bool isNotAuthenticated() {
    return !authProvider.isSessionBootstrapping &&
        !authProvider.isAuthenticated;
  }

  /// Check if user has specific role
  bool hasRole(AppUserRole role) {
    return authProvider.currentUser?.role == role;
  }

  /// Check if user has any of the specified roles
  bool hasAnyRole(List<AppUserRole> roles) {
    final userRole = authProvider.currentUser?.role;
    return userRole != null && roles.contains(userRole);
  }

  /// Check if user has all specified roles
  bool hasAllRoles(List<AppUserRole> roles) {
    final userRole = authProvider.currentUser?.role;
    return userRole != null && roles.contains(userRole);
  }

  /// Check if user is student
  bool isStudent() {
    return authProvider.currentUser?.role == AppUserRole.student;
  }

  /// Check if user is instructor
  bool isInstructor() {
    return authProvider.currentUser?.role == AppUserRole.instructor;
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return authProvider.currentUser?.id;
  }

  /// Get current user
  AppUser? getCurrentUser() {
    return authProvider.currentUser;
  }
}
