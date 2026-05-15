import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/auth_service.dart';
import '../services/auth_exceptions.dart';
import '../services/firestore_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    AuthService? authService,
    FirestoreService? firestoreService,
  }) : _authService = authService ?? AuthService.instance,
       _firestoreService = firestoreService ?? FirestoreService.instance;

  final AuthService _authService;
  final FirestoreService _firestoreService;
  AppUser? _currentUser;

  @override
  AppUser? getCurrentUser() => _currentUser;

  @override
  Stream<AppUser?> authStateChanges() {
    return _authService.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        _currentUser = null;
        return null;
      }
      final cached = _currentUser;
      final profile = await _resolveUserProfile(
        firebaseUser,
        cachedUser: cached?.id == firebaseUser.uid ? cached : null,
      );
      _currentUser = profile;
      return profile;
    });
  }

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final credential = await _authService.signInWithEmail(
      email: email.trim(),
      password: password,
    );
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Could not login right now.');
    }
    final profile = await _resolveUserProfile(firebaseUser);
    _currentUser = profile;
    return profile;
  }

  @override
  Future<AppUser> loginWithGoogle({AppUserRole? roleForNewUser}) async {
    final credential = await _authService.signInWithGoogle();
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Could not login with Google right now.');
    }
    try {
      final profile = await _resolveUserProfile(
        firebaseUser,
        explicitRole: roleForNewUser,
      );
      _currentUser = profile;
      return profile;
    } on RoleSelectionRequiredException {
      await _authService.signOut();
      rethrow;
    }
  }

  @override
  Future<AppUser> updateProfile({
    required String name,
    required String email,
    required AppUserRole role,
    String? phone,
    String? photoUrl,
  }) async {
    final current = _currentUser;
    if (current == null) {
      throw Exception('No active user session.');
    }

    final trimmedName = name.trim();
    final trimmedEmail = email.trim();
    final trimmedPhone = phone?.trim() ?? current.phone;
    final trimmedPhotoUrl = photoUrl?.trim() ?? current.photoUrl;

    await _firestoreService.updateUserProfile(
      uid: current.id,
      name: trimmedName,
      email: trimmedEmail,
      role: role,
      phone: trimmedPhone,
      image: trimmedPhotoUrl,
    );

    final updated = current.copyWith(
      name: trimmedName,
      email: trimmedEmail,
      role: role,
      phone: trimmedPhone,
      photoUrl: trimmedPhotoUrl,
    );
    _currentUser = updated;
    return updated;
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required AppUserRole role,
  }) async {
    final credential = await _authService.registerWithEmail(
      email: email.trim(),
      password: password,
    );
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Could not create account right now.');
    }
    final user = AppUser(
      id: firebaseUser.uid,
      name: name.trim(),
      email: email.trim(),
      role: role,
    );

    await _firestoreService.updateUserProfile(
      uid: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
    );

    _currentUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    await _authService.signOut();
    _currentUser = null;
  }

  @override
  Future<bool> sendPasswordResetEmail({required String email}) async {
    return await _authService.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> resetPasswordWithCode({
    required String oobCode,
    required String newPassword,
  }) async {
    await _authService.resetPasswordWithCode(
      oobCode: oobCode,
      newPassword: newPassword,
    );
  }

  /// Generate OTP and send to email
  @override
  Future<String> generateAndSendPasswordResetOtp({
    required String email,
  }) async {
    final otp = await _firestoreService.generateAndSendPasswordResetOtp(
      email: email.trim(),
    );
    // في التطبيق الحقيقي، ستحتاج إلى إرسال البريد هنا
    // مع الكود في الرسالة
    return otp;
  }

  /// Verify OTP
  @override
  Future<bool> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    return await _firestoreService.verifyPasswordResetOtp(
      email: email.trim(),
      otp: otp.trim(),
    );
  }

  /// Reset password with verified OTP
  @override
  Future<PasswordResetOtpResult> resetPasswordWithOtp({
    required String email,
    required String newPassword,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      await _firestoreService.ensurePasswordResetOtpVerified(normalizedEmail);

      try {
        await _authService.resetPasswordWithOtp(
          email: normalizedEmail,
          newPassword: newPassword,
        );
        await _firestoreService.consumePasswordResetOtp(normalizedEmail);
        return PasswordResetOtpResult.passwordUpdated;
      } on FirebaseAuthException catch (error) {
        final code = error.code.trim().toLowerCase();
        if (code != 'requires-backend' && code != 'requires-recent-login') {
          rethrow;
        }
      }

      await _authService.sendPasswordResetEmail(email: normalizedEmail);
      await _firestoreService.consumePasswordResetOtp(normalizedEmail);
      return PasswordResetOtpResult.resetLinkSent;
    } catch (_) {
      rethrow;
    }
  }

  Future<AppUser> _resolveUserProfile(
    User firebaseUser, {
    AppUserRole? explicitRole,
    AppUser? cachedUser,
  }) async {
    try {
      final existing = await _firestoreService
          .getUserProfile(firebaseUser.uid)
          .timeout(const Duration(seconds: 12), onTimeout: () => null);
      if (existing != null) {
        return existing;
      }

      final inferredRole =
          explicitRole ??
          await _firestoreService
              .inferRoleForExistingAuthUser(firebaseUser.uid)
              .timeout(
                const Duration(seconds: 12),
                onTimeout: () => AppUserRole.student,
              );

      return await _firestoreService
          .ensureUserProfile(
            firebaseUser: firebaseUser,
            roleForNewUser: inferredRole,
          )
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () =>
                _fallbackUserFromFirebase(firebaseUser, role: inferredRole),
          );
    } catch (_) {
      final cachedRole = cachedUser?.role;
      final recoveredRole =
          explicitRole ??
          cachedRole ??
          await _safeInferRole(firebaseUser.uid, fallback: AppUserRole.student);
      final fallback = _fallbackUserFromFirebase(
        firebaseUser,
        role: recoveredRole,
      );
      unawaited(
        _firestoreService
            .updateUserProfile(
              uid: fallback.id,
              name: fallback.name,
              email: fallback.email,
              role: fallback.role,
            )
            .catchError((_) {}),
      );
      return fallback;
    }
  }

  Future<AppUserRole> _safeInferRole(
    String uid, {
    required AppUserRole fallback,
  }) async {
    try {
      return await _firestoreService
          .inferRoleForExistingAuthUser(uid)
          .timeout(const Duration(seconds: 8), onTimeout: () => fallback);
    } catch (_) {
      return fallback;
    }
  }

  AppUser _fallbackUserFromFirebase(
    User firebaseUser, {
    required AppUserRole role,
  }) {
    final displayName = firebaseUser.displayName?.trim() ?? '';
    final email = firebaseUser.email?.trim() ?? '';
    final resolvedName = displayName.isNotEmpty
        ? displayName
        : (email.isNotEmpty ? email.split('@').first : 'User');
    return AppUser(
      id: firebaseUser.uid,
      name: resolvedName,
      email: email,
      role: role,
    );
  }
}
