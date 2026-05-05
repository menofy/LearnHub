import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:learnhub/core/auth_constants.dart';
import 'package:learnhub/data/services/auth_exceptions.dart';
import 'package:learnhub/domain/entities/app_user.dart';
import 'package:learnhub/domain/repositories/auth_repository.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';

void main() {
  late _FakeAuthRepository repository;
  late AuthProvider provider;

  const student = AppUser(
    id: 'student-1',
    name: 'Student User',
    email: 'student@example.com',
    role: AppUserRole.student,
  );

  const instructor = AppUser(
    id: 'instructor-1',
    name: 'Instructor User',
    email: 'teacher@example.com',
    role: AppUserRole.instructor,
  );

  setUp(() {
    repository = _FakeAuthRepository();
    provider = AuthProvider(repository);
  });

  tearDown(() {
    provider.dispose();
    repository.dispose();
  });

  test('starts unauthenticated when repository has no cached user', () {
    expect(provider.currentUser, isNull);
    expect(provider.isAuthenticated, isFalse);
    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNull);
  });

  test('login stores the authenticated user and trims email input', () async {
    repository.loginResult = student;

    final success = await provider.login(
      email: '  student@example.com  ',
      password: 'password123',
    );

    expect(success, isTrue);
    expect(provider.currentUser, same(student));
    expect(provider.isAuthenticated, isTrue);
    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNull);
    expect(repository.lastLoginEmail, 'student@example.com');
  });

  test(
    'login failure exposes a friendly invalid credentials message',
    () async {
      repository.loginError = Exception('firebase_auth/invalid-credential');

      final success = await provider.login(
        email: 'student@example.com',
        password: 'bad-password',
      );

      expect(success, isFalse);
      expect(provider.currentUser, isNull);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, AuthConstants.invalidCredentialsMessage);
    },
  );

  test(
    'register creates then signs out so new users continue setup manually',
    () async {
      repository.registerResult = instructor;

      final success = await provider.register(
        name: '  Instructor User  ',
        email: '  teacher@example.com  ',
        password: 'password123',
        role: AppUserRole.instructor,
      );

      expect(success, isTrue);
      expect(provider.currentUser, isNull);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.errorMessage, isNull);
      expect(repository.logoutCallCount, 1);
      expect(repository.lastRegisterName, 'Instructor User');
      expect(repository.lastRegisterEmail, 'teacher@example.com');
      expect(repository.lastRegisterRole, AppUserRole.instructor);
    },
  );

  test('register failure maps duplicate email to friendly message', () async {
    repository.registerError = Exception('firebase_auth/email-already-in-use');

    final success = await provider.register(
      name: 'Student User',
      email: 'student@example.com',
      password: 'password123',
      role: AppUserRole.student,
    );

    expect(success, isFalse);
    expect(provider.currentUser, isNull);
    expect(provider.errorMessage, AuthConstants.userAlreadyExistsMessage);
  });

  test(
    'google login stores user when a role is supplied for a new account',
    () async {
      repository.googleLoginResult = instructor;

      final success = await provider.loginWithGoogle(
        roleForNewUser: AppUserRole.instructor,
      );

      expect(success, isTrue);
      expect(provider.currentUser, same(instructor));
      expect(provider.isAuthenticated, isTrue);
      expect(provider.requiresRoleSelection, isFalse);
      expect(repository.lastGoogleRole, AppUserRole.instructor);
    },
  );

  test(
    'google login asks for role selection when repository requires it',
    () async {
      repository.googleLoginError = const RoleSelectionRequiredException();

      final success = await provider.loginWithGoogle();

      expect(success, isFalse);
      expect(provider.currentUser, isNull);
      expect(provider.requiresRoleSelection, isTrue);
      expect(
        provider.errorMessage,
        'Please choose a role to continue with Google.',
      );
    },
  );

  test('logout clears the current user', () async {
    repository.loginResult = student;
    await provider.login(email: student.email, password: 'password123');

    await provider.logout();

    expect(provider.currentUser, isNull);
    expect(provider.isAuthenticated, isFalse);
    expect(provider.isLoading, isFalse);
    expect(repository.logoutCallCount, 1);
  });

  test('auth state stream updates current user and signed-out state', () async {
    repository.emitAuthState(student);
    await pumpEventQueue();

    expect(provider.currentUser, same(student));
    expect(provider.isAuthenticated, isTrue);

    repository.emitAuthState(null);
    await pumpEventQueue();

    expect(provider.currentUser, isNull);
    expect(provider.isAuthenticated, isFalse);
  });

  test(
    'requestPasswordReset validates empty email before repository call',
    () async {
      final success = await provider.requestPasswordReset('   ');

      expect(success, isFalse);
      expect(provider.errorMessage, 'Email is required.');
      expect(repository.passwordResetCallCount, 0);
    },
  );

  test('requestPasswordReset delegates trimmed email to repository', () async {
    repository.passwordResetResult = true;

    final success = await provider.requestPasswordReset(
      '  student@example.com  ',
    );

    expect(success, isTrue);
    expect(repository.passwordResetCallCount, 1);
    expect(repository.lastPasswordResetEmail, 'student@example.com');
    expect(provider.errorMessage, isNull);
  });

  test(
    'password reset OTP flow stores pending data after send and verify',
    () async {
      repository.generatedOtp = '123456';
      repository.verifyOtpResult = true;

      final sent = await provider.sendPasswordResetOtp(' student@example.com ');
      final verified = await provider.verifyPasswordResetOtp(
        'student@example.com',
        '123456',
      );

      expect(sent, isTrue);
      expect(verified, isTrue);
      expect(provider.pendingSignupEmail, 'student@example.com');
      expect(repository.lastGeneratedOtpEmail, 'student@example.com');
      expect(repository.lastVerifyOtpEmail, 'student@example.com');
      expect(repository.lastVerifyOtp, '123456');
    },
  );

  test(
    'resetPasswordWithOtp rejects short passwords without repository call',
    () async {
      final success = await provider.resetPasswordWithOtp(
        email: 'student@example.com',
        newPassword: 'short',
      );

      expect(success, isFalse);
      expect(
        provider.errorMessage,
        'Password must be at least ${AuthConstants.minPasswordLength} characters.',
      );
      expect(repository.resetWithOtpCallCount, 0);
    },
  );

  test('resetPasswordWithCode delegates valid reset code', () async {
    final success = await provider.resetPasswordWithCode(
      oobCode: 'code-123',
      newPassword: 'password123',
    );

    expect(success, isTrue);
    expect(repository.lastResetCode, 'code-123');
    expect(repository.lastResetCodePassword, 'password123');
  });

  test('updateProfile requires an authenticated user', () async {
    final success = await provider.updateProfile(name: 'New Name');

    expect(success, isFalse);
    expect(provider.errorMessage, 'No active user session.');
    expect(repository.updateProfileCallCount, 0);
  });

  test('updateProfile persists profile changes for the current user', () async {
    repository.loginResult = student;
    repository.updateProfileResult = student.copyWith(
      name: 'Updated Student',
      phone: '01000000000',
    );
    await provider.login(email: student.email, password: 'password123');

    final success = await provider.updateProfile(
      name: '  Updated Student  ',
      phone: ' 01000000000 ',
    );

    expect(success, isTrue);
    expect(provider.currentUser?.name, 'Updated Student');
    expect(provider.currentUser?.phone, '01000000000');
    expect(repository.lastUpdateName, 'Updated Student');
    expect(repository.lastUpdatePhone, '01000000000');
  });
}

class _FakeAuthRepository implements AuthRepository {
  final _authStateController = StreamController<AppUser?>.broadcast();

  AppUser? cachedUser;
  AppUser? loginResult;
  AppUser? registerResult;
  AppUser? googleLoginResult;
  AppUser? updateProfileResult;

  Object? loginError;
  Object? registerError;
  Object? googleLoginError;
  Object? passwordResetError;
  Object? resetCodeError;
  Object? generatedOtpError;
  Object? verifyOtpError;
  Object? resetOtpError;

  bool passwordResetResult = true;
  bool verifyOtpResult = true;
  String generatedOtp = '654321';

  String? lastLoginEmail;
  String? lastRegisterName;
  String? lastRegisterEmail;
  AppUserRole? lastRegisterRole;
  AppUserRole? lastGoogleRole;
  String? lastPasswordResetEmail;
  String? lastResetCode;
  String? lastResetCodePassword;
  String? lastGeneratedOtpEmail;
  String? lastVerifyOtpEmail;
  String? lastVerifyOtp;
  String? lastResetOtpEmail;
  String? lastResetOtpPassword;
  String? lastUpdateName;
  String? lastUpdatePhone;

  int logoutCallCount = 0;
  int passwordResetCallCount = 0;
  int resetWithOtpCallCount = 0;
  int updateProfileCallCount = 0;

  @override
  Stream<AppUser?> authStateChanges() => _authStateController.stream;

  @override
  AppUser? getCurrentUser() => cachedUser;

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    lastLoginEmail = email;
    final error = loginError;
    if (error != null) throw error;
    final user = loginResult ?? cachedUser;
    if (user == null) {
      throw const InvalidCredentialsException();
    }
    cachedUser = user;
    return user;
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required AppUserRole role,
  }) async {
    lastRegisterName = name;
    lastRegisterEmail = email;
    lastRegisterRole = role;
    final error = registerError;
    if (error != null) throw error;
    final user =
        registerResult ??
        AppUser(id: 'registered-1', name: name, email: email, role: role);
    cachedUser = user;
    return user;
  }

  @override
  Future<AppUser> loginWithGoogle({AppUserRole? roleForNewUser}) async {
    lastGoogleRole = roleForNewUser;
    final error = googleLoginError;
    if (error != null) throw error;
    final user =
        googleLoginResult ??
        AppUser(
          id: 'google-1',
          name: 'Google User',
          email: 'google@example.com',
          role: roleForNewUser ?? AppUserRole.student,
        );
    cachedUser = user;
    return user;
  }

  @override
  Future<AppUser> updateProfile({
    required String name,
    required String email,
    required AppUserRole role,
    String? phone,
    String? photoUrl,
  }) async {
    updateProfileCallCount++;
    lastUpdateName = name;
    lastUpdatePhone = phone;
    final user =
        updateProfileResult ??
        AppUser(
          id: cachedUser?.id ?? 'updated-1',
          name: name,
          email: email,
          role: role,
          phone: phone ?? '',
          photoUrl: photoUrl ?? '',
        );
    cachedUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    logoutCallCount++;
    cachedUser = null;
  }

  @override
  Future<bool> sendPasswordResetEmail({required String email}) async {
    passwordResetCallCount++;
    lastPasswordResetEmail = email;
    final error = passwordResetError;
    if (error != null) throw error;
    return passwordResetResult;
  }

  @override
  Future<void> resetPasswordWithCode({
    required String oobCode,
    required String newPassword,
  }) async {
    lastResetCode = oobCode;
    lastResetCodePassword = newPassword;
    final error = resetCodeError;
    if (error != null) throw error;
  }

  Future<String> generateAndSendPasswordResetOtp({
    required String email,
  }) async {
    lastGeneratedOtpEmail = email;
    final error = generatedOtpError;
    if (error != null) throw error;
    return generatedOtp;
  }

  Future<bool> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    lastVerifyOtpEmail = email;
    lastVerifyOtp = otp;
    final error = verifyOtpError;
    if (error != null) throw error;
    return verifyOtpResult;
  }

  Future<void> resetPasswordWithOtp({
    required String email,
    required String newPassword,
  }) async {
    resetWithOtpCallCount++;
    lastResetOtpEmail = email;
    lastResetOtpPassword = newPassword;
    final error = resetOtpError;
    if (error != null) throw error;
  }

  void emitAuthState(AppUser? user) {
    cachedUser = user;
    _authStateController.add(user);
  }

  void dispose() {
    _authStateController.close();
  }
}
