import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

import '../auth_constants.dart';

class AppErrorMapper {
  const AppErrorMapper._();

  static String auth(Object error) {
    final code = _firebaseCode(error);
    if (code != null) {
      switch (code) {
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-email':
          return AuthConstants.invalidCredentialsMessage;
        case 'email-already-in-use':
          return AuthConstants.userAlreadyExistsMessage;
        case 'user-not-found':
          return AuthConstants.userNotFoundMessage;
        case 'network-request-failed':
        case 'unavailable':
          return AuthConstants.networkErrorMessage;
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled.';
        case 'weak-password':
          return 'Password is too weak. Please choose a stronger password.';
        case 'auth-timeout':
          return AuthConstants.timeoutErrorMessage;
        case 'permission-denied':
          return permissionDenied;
        case 'google-sign-in-aborted':
          return 'Google sign-in was cancelled.';
        case 'google-id-token-missing':
        case 'google-token-missing':
          return 'Google sign-in failed. Please retry and choose a Google account.';
        case 'google-sign-in-failed':
          return 'Google sign-in failed. Please try again.';
      }
    }

    final text = _normalized(error);
    if (_isTimeout(error, text)) {
      return AuthConstants.timeoutErrorMessage;
    }
    if (_isNetwork(text)) {
      return AuthConstants.networkErrorMessage;
    }
    if (text.contains('permission-denied') ||
        text.contains('permission denied')) {
      return permissionDenied;
    }
    if (text.contains('otp not found')) {
      return 'OTP not found. Request a new code.';
    }
    if (text.contains('otp expired')) {
      return 'OTP expired. Request a new code.';
    }
    if (text.contains('otp already used')) {
      return 'OTP already used. Request a new code.';
    }
    if (text.contains('invalid otp')) {
      return 'Invalid OTP code.';
    }
    if (text.contains('user not found')) {
      return AuthConstants.userNotFoundMessage;
    }
    if (text.contains('email-already-in-use') ||
        text.contains('email already') ||
        text.contains('already exists')) {
      return AuthConstants.userAlreadyExistsMessage;
    }
    if (text.contains('invalid-credential') ||
        text.contains('invalid credential') ||
        text.contains('wrong-password')) {
      return AuthConstants.invalidCredentialsMessage;
    }
    return AuthConstants.genericErrorMessage;
  }

  static String data(Object error, {required String fallback}) {
    final code = _firebaseCode(error);
    if (code != null) {
      switch (code) {
        case 'permission-denied':
          return permissionDenied;
        case 'unavailable':
        case 'network-request-failed':
          return network;
        case 'deadline-exceeded':
        case 'cancelled':
          return timeout;
        case 'not-found':
          return 'The requested data was not found.';
        case 'resource-exhausted':
          return 'Service is busy right now. Please try again soon.';
        case 'unauthenticated':
          return 'Please log in again to continue.';
      }
    }

    final text = _normalized(error);
    if (_isTimeout(error, text)) {
      return timeout;
    }
    if (_isNetwork(text)) {
      return network;
    }
    if (text.contains('permission-denied') ||
        text.contains('permission denied')) {
      return permissionDenied;
    }
    if (text.contains('unauthenticated')) {
      return 'Please log in again to continue.';
    }
    return fallback;
  }

  static String external(Object error, {required String fallback}) {
    final text = _normalized(error);
    if (_isTimeout(error, text)) {
      return timeout;
    }
    if (_isNetwork(text)) {
      return network;
    }
    return _cleanExceptionPrefix(error.toString()).trim().isEmpty
        ? fallback
        : _cleanExceptionPrefix(error.toString());
  }

  static const String network =
      'Network error. Please check your connection and try again.';
  static const String timeout = 'Request timed out. Please try again.';
  static const String permissionDenied =
      'You do not have permission to perform this action.';

  static String? _firebaseCode(Object error) {
    if (error is FirebaseException) {
      return error.code.trim().toLowerCase();
    }
    return null;
  }

  static bool _isTimeout(Object error, String text) {
    return error is TimeoutException ||
        text.contains('timeoutexception') ||
        text.contains('timed out') ||
        text.contains('deadline-exceeded');
  }

  static bool _isNetwork(String text) {
    return text.contains('socketexception') ||
        text.contains('clientexception') ||
        text.contains('failed host lookup') ||
        text.contains('network-request-failed') ||
        text.contains('unavailable') ||
        text.contains('no address associated with hostname') ||
        text.contains('connection refused');
  }

  static String _normalized(Object error) {
    return error.toString().toLowerCase();
  }

  static String _cleanExceptionPrefix(String value) {
    return value
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^\[.*?\]\s*'), '');
  }
}
