import 'package:flutter_test/flutter_test.dart';
import 'package:learnhub/core/utils/auth_validators.dart';

void main() {
  group('AuthValidators.validateEmail', () {
    test('accepts valid email addresses', () {
      expect(AuthValidators.validateEmail('student@example.com'), isNull);
      expect(AuthValidators.validateEmail('first.last+tag@example.co'), isNull);
    });

    test('rejects empty and malformed emails', () {
      expect(AuthValidators.validateEmail(''), 'Email is required');
      expect(
        AuthValidators.validateEmail('not-an-email'),
        'Please enter a valid email address',
      );
    });
  });

  group('AuthValidators.validatePassword', () {
    test('accepts strong passwords', () {
      expect(AuthValidators.validatePassword('Password1!'), isNull);
    });

    test('rejects common weak password cases', () {
      expect(AuthValidators.validatePassword(''), 'Password is required');
      expect(
        AuthValidators.validatePassword('Short1!'),
        'Password must be at least 8 characters long',
      );
      expect(
        AuthValidators.validatePassword('password1!'),
        'Password must contain at least one uppercase letter',
      );
      expect(
        AuthValidators.validatePassword('PASSWORD1!'),
        'Password must contain at least one lowercase letter',
      );
      expect(
        AuthValidators.validatePassword('Password!'),
        'Password must contain at least one digit',
      );
      expect(
        AuthValidators.validatePassword('Password1'),
        'Password must contain at least one special character',
      );
    });
  });

  group('AuthValidators.validatePasswordConfirmation', () {
    test('requires matching confirmation', () {
      expect(
        AuthValidators.validatePasswordConfirmation('', 'Password1!'),
        'Please confirm your password',
      );
      expect(
        AuthValidators.validatePasswordConfirmation('Other1!', 'Password1!'),
        'Passwords do not match',
      );
      expect(
        AuthValidators.validatePasswordConfirmation('Password1!', 'Password1!'),
        isNull,
      );
    });
  });

  group('AuthValidators.validateName', () {
    test('accepts names with spaces, hyphens, and apostrophes', () {
      expect(AuthValidators.validateName("Anne-Marie O'Neil"), isNull);
    });

    test('rejects invalid names', () {
      expect(AuthValidators.validateName(''), 'Name is required');
      expect(
        AuthValidators.validateName('Al'),
        'Name must be at least 3 characters long',
      );
      expect(
        AuthValidators.validateName('User123'),
        'Name can only contain letters, spaces, hyphens, and apostrophes',
      );
    });
  });

  group('AuthValidators.validateOTP and validatePIN', () {
    test('validateOTP accepts only six digits', () {
      expect(AuthValidators.validateOTP('123456'), isNull);
      expect(AuthValidators.validateOTP(''), 'OTP is required');
      expect(AuthValidators.validateOTP('1234'), 'OTP must be 6 digits');
      expect(
        AuthValidators.validateOTP('12345a'),
        'OTP must contain only digits',
      );
    });

    test('validatePIN accepts only four digits', () {
      expect(AuthValidators.validatePIN('1234'), isNull);
      expect(AuthValidators.validatePIN(''), 'PIN is required');
      expect(AuthValidators.validatePIN('123'), 'PIN must be 4 digits');
      expect(
        AuthValidators.validatePIN('12a4'),
        'PIN must contain only digits',
      );
    });
  });

  group('AuthValidators.validateUsername', () {
    test('accepts letters numbers underscores and hyphens', () {
      expect(AuthValidators.validateUsername('student_01-test'), isNull);
    });

    test('rejects invalid usernames', () {
      expect(AuthValidators.validateUsername(''), 'Username is required');
      expect(
        AuthValidators.validateUsername('ab'),
        'Username must be at least 3 characters long',
      );
      expect(
        AuthValidators.validateUsername('bad user'),
        'Username can only contain letters, numbers, underscores, and hyphens',
      );
    });
  });
}
