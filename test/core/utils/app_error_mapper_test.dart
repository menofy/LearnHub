import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnhub/core/auth_constants.dart';
import 'package:learnhub/core/utils/app_error_mapper.dart';

void main() {
  group('AppErrorMapper.auth', () {
    test('maps invalid credentials', () {
      final message = AppErrorMapper.auth(
        FirebaseException(plugin: 'firebase_auth', code: 'invalid-credential'),
      );

      expect(message, AuthConstants.invalidCredentialsMessage);
    });

    test('maps duplicate email', () {
      final message = AppErrorMapper.auth(
        FirebaseException(
          plugin: 'firebase_auth',
          code: 'email-already-in-use',
        ),
      );

      expect(message, AuthConstants.userAlreadyExistsMessage);
    });

    test('maps Google cancellation', () {
      final message = AppErrorMapper.auth(
        FirebaseException(
          plugin: 'firebase_auth',
          code: 'google-sign-in-aborted',
        ),
      );

      expect(message, 'Google sign-in was cancelled.');
    });

    test('maps OTP errors from wrapped exception text', () {
      final message = AppErrorMapper.auth(
        Exception(
          'OTP verification failed: Exception: OTP expired. Request a new one.',
        ),
      );

      expect(message, 'OTP expired. Request a new code.');
    });
  });

  group('AppErrorMapper.data', () {
    test('maps permission denied', () {
      final message = AppErrorMapper.data(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
        fallback: 'Fallback',
      );

      expect(message, AppErrorMapper.permissionDenied);
    });

    test('maps unavailable/network errors', () {
      final message = AppErrorMapper.data(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        fallback: 'Fallback',
      );

      expect(message, AppErrorMapper.network);
    });

    test('maps timeout errors', () {
      final message = AppErrorMapper.data(
        TimeoutException('slow'),
        fallback: 'Fallback',
      );

      expect(message, AppErrorMapper.timeout);
    });

    test('keeps fallback for unknown errors', () {
      final message = AppErrorMapper.data(
        Exception('something unexpected'),
        fallback: 'Fallback',
      );

      expect(message, 'Fallback');
    });
  });
}
