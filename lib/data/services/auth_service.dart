import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _googleInitFuture;
  static const List<String> _googleScopes = <String>[
    'email',
    'profile',
    'openid',
  ];
  static const Duration _googleAuthTimeout = Duration(seconds: 35);

  String get _googleServerClientId {
    const value = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
    return value.trim();
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth
        .signInWithEmailAndPassword(email: email, password: password)
        .timeout(const Duration(seconds: 25));
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) {
    return _auth
        .createUserWithEmailAndPassword(email: email, password: password)
        .timeout(const Duration(seconds: 25));
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    try {
      final googleUser = _googleSignIn.supportsAuthenticate()
          ? await _googleSignIn
                .authenticate(scopeHint: _googleScopes)
                .timeout(_googleAuthTimeout)
          : await _googleSignIn.attemptLightweightAuthentication()?.timeout(
              _googleAuthTimeout,
            );

      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'google-sign-in-aborted',
          message: 'Google sign-in was cancelled.',
        );
      }

      final idToken = googleUser.authentication.idToken;
      var accessToken = await googleUser.authorizationClient
          .authorizationForScopes(_googleScopes)
          .then((value) => value?.accessToken);

      if (accessToken == null || accessToken.isEmpty) {
        try {
          accessToken = await googleUser.authorizationClient
              .authorizeScopes(_googleScopes)
              .then((value) => value.accessToken);
        } catch (_) {
          // Keep null and rely on ID token if available.
        }
      }

      if ((idToken == null || idToken.isEmpty) &&
          (accessToken == null || accessToken.isEmpty)) {
        throw FirebaseAuthException(
          code: 'google-token-missing',
          message: 'Could not get Google auth tokens.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        idToken: (idToken == null || idToken.isEmpty) ? null : idToken,
        accessToken: (accessToken == null || accessToken.isEmpty)
            ? null
            : accessToken,
      );
      return _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw FirebaseAuthException(
          code: 'google-sign-in-aborted',
          message: 'Google sign-in was cancelled.',
        );
      }
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: error.description,
      );
    } on TimeoutException {
      throw FirebaseAuthException(
        code: 'auth-timeout',
        message: 'Google sign-in timed out. Please try again.',
      );
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore Google sign-out failures if user used email auth.
    }
  }

  /// إرسال رابط إعادة تعيين كلمة المرور إلى البريد الإلكتروني
  Future<bool> sendPasswordResetEmail({required String email}) async {
    try {
      // أرسل رابط إعادة تعيين كلمة المرور
      // Firebase سيتعامل مع التحقق من وجود الحساب
      await _auth
          .sendPasswordResetEmail(email: email.trim())
          .timeout(const Duration(seconds: 8));

      return true;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(code: 'unknown', message: e.toString());
    }
  }

  /// تعيين كلمة مرور جديدة باستخدام كود الإعادة
  /// (هذا يتم عادة بعد النقر على الرابط في البريد من قبل المستخدم)
  /// للعمل مع Firebase Confirmation Code من البريد:
  Future<void> resetPasswordWithCode({
    required String oobCode,
    required String newPassword,
  }) async {
    try {
      await _auth
          .confirmPasswordReset(code: oobCode, newPassword: newPassword)
          .timeout(const Duration(seconds: 8));
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(code: 'unknown', message: e.toString());
    }
  }

  /// تعيين كلمة مرور جديدة باستخدام OTP من Firestore
  /// يتم استدعاء هذا بعد التحقق من صحة OTP
  Future<void> resetPasswordWithOtp({
    required String email,
    required String newPassword,
  }) async {
    try {
      // في الواقع، نحتاج إلى استخدام updatePassword للمستخدم الحالي
      // لكن هنا المستخدم قد لا يكون مسجل دخول
      // سنستخدم Admin SDK أو Firebase Cloud Functions في الإنتاج
      // للآن، نترك هذا للـ repository
      throw UnimplementedError(
        'Use AuthRepository.resetPasswordWithOtp with proper backend implementation',
      );
    } catch (e) {
      throw FirebaseAuthException(code: 'unknown', message: e.toString());
    }
  }

  Future<void> _ensureGoogleInitialized() {
    final existing = _googleInitFuture;
    if (existing != null) {
      return existing;
    }
    _googleInitFuture = _googleSignIn.initialize(
      serverClientId: _googleServerClientId.isEmpty
          ? null
          : _googleServerClientId,
    );
    return _googleInitFuture!;
  }
}
