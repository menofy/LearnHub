import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:learnhub/core/navigation/auth_guard.dart';
import 'package:learnhub/domain/entities/app_user.dart';
import 'package:learnhub/domain/repositories/auth_repository.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAuthRepository repository;
  late AuthProvider authProvider;
  late AuthGuard guard;

  const student = AppUser(
    id: 'student-1',
    name: 'Student',
    email: 'student@example.com',
    role: AppUserRole.student,
  );

  const instructor = AppUser(
    id: 'instructor-1',
    name: 'Instructor',
    email: 'instructor@example.com',
    role: AppUserRole.instructor,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    authProvider.dispose();
    repository.dispose();
  });

  test('reports unauthenticated state', () async {
    repository = _FakeAuthRepository();
    authProvider = AuthProvider(repository);
    guard = AuthGuard(authProvider: authProvider);

    expect(guard.isResolvingSession(), isTrue);
    expect(guard.isAuthenticated(), isFalse);
    expect(guard.isNotAuthenticated(), isFalse);
    expect(guard.getCurrentUser(), isNull);
    expect(guard.getCurrentUserId(), isNull);
    expect(guard.isStudent(), isFalse);
    expect(guard.isInstructor(), isFalse);

    repository.emit(null);
    await pumpEventQueue();

    expect(guard.isResolvingSession(), isFalse);
    expect(guard.isAuthenticated(), isFalse);
    expect(guard.isNotAuthenticated(), isTrue);
  });

  test('reports student role state', () async {
    repository = _FakeAuthRepository(cachedUser: student);
    authProvider = AuthProvider(repository);
    guard = AuthGuard(authProvider: authProvider);

    repository.emit(student);
    await pumpEventQueue();

    expect(guard.isResolvingSession(), isFalse);
    expect(guard.isAuthenticated(), isTrue);
    expect(guard.isNotAuthenticated(), isFalse);
    expect(guard.hasRole(AppUserRole.student), isTrue);
    expect(guard.hasRole(AppUserRole.instructor), isFalse);
    expect(guard.hasAnyRole(const [AppUserRole.student]), isTrue);
    expect(guard.isStudent(), isTrue);
    expect(guard.isInstructor(), isFalse);
    expect(guard.getCurrentUserId(), 'student-1');
  });

  test('reacts to auth state stream changes', () async {
    repository = _FakeAuthRepository();
    authProvider = AuthProvider(repository);
    guard = AuthGuard(authProvider: authProvider);

    repository.emit(instructor);
    await pumpEventQueue();

    expect(guard.isResolvingSession(), isFalse);
    expect(guard.isAuthenticated(), isTrue);
    expect(guard.isInstructor(), isTrue);
    expect(guard.getCurrentUser(), same(instructor));

    repository.emit(null);
    await pumpEventQueue();

    expect(guard.isAuthenticated(), isFalse);
    expect(guard.isNotAuthenticated(), isTrue);
    expect(guard.getCurrentUser(), isNull);
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.cachedUser});

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? cachedUser;

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  @override
  AppUser? getCurrentUser() => cachedUser;

  void emit(AppUser? user) {
    cachedUser = user;
    _controller.add(user);
  }

  void dispose() {
    _controller.close();
  }

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required AppUserRole role,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> loginWithGoogle({AppUserRole? roleForNewUser}) async {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> updateProfile({
    required String name,
    required String email,
    required AppUserRole role,
    String? phone,
    String? photoUrl,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<bool> sendPasswordResetEmail({required String email}) async {
    throw UnimplementedError();
  }

  @override
  Future<String> generateAndSendPasswordResetOtp({
    required String email,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<PasswordResetOtpResult> resetPasswordWithOtp({
    required String email,
    required String newPassword,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> resetPasswordWithCode({
    required String oobCode,
    required String newPassword,
  }) async {
    throw UnimplementedError();
  }
}
