import '../entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();
  Future<AppUser> login({required String email, required String password});
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required AppUserRole role,
  });
  Future<AppUser> loginWithGoogle({AppUserRole? roleForNewUser});
  Future<AppUser> updateProfile({
    required String name,
    required String email,
    required AppUserRole role,
    String? phone,
    String? photoUrl,
  });
  Future<void> logout();
  AppUser? getCurrentUser();

  /// يرسل رابط إعادة تعيين كلمة المرور إلى البريد الإلكتروني
  /// يتحقق أولاً من وجود حساب مع هذا البريد
  Future<bool> sendPasswordResetEmail({required String email});

  /// تعيين كلمة مرور جديدة باستخدام كود الإعادة من البريد
  Future<void> resetPasswordWithCode({
    required String oobCode,
    required String newPassword,
  });
}
