import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:learnhub/core/auth_constants.dart';
import 'package:learnhub/core/utils/app_error_mapper.dart';
import 'package:learnhub/data/services/auth_exceptions.dart';
import 'package:learnhub/domain/entities/app_user.dart';
import 'package:learnhub/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authRepository) {
    _currentUser = _authRepository.getCurrentUser();
    _hydratePreferencesCache();
    _authSub = _authRepository.authStateChanges().listen(
      (user) {
        _currentUser = user;
        unawaited(_syncPersistedSession(user));
        _markSessionBootstrapComplete();
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        _currentUser = null;
        _errorMessage = _friendlyError(error);
        unawaited(_clearPersistedSession());
        _markSessionBootstrapComplete();
        notifyListeners();
      },
    );
  }

  final AuthRepository _authRepository;
  StreamSubscription<AppUser?>? _authSub;
  SharedPreferences? _prefs;
  bool _isSessionBootstrapping = true;

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _requiresRoleSelection = false;

  String? _pendingSignupName;
  String? _pendingSignupEmail;
  String? _pendingSignupOtp;
  DateTime? _pendingSignupRequestedAt;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isSessionBootstrapping => _isSessionBootstrapping;
  String? get errorMessage => _errorMessage;
  bool get requiresRoleSelection => _requiresRoleSelection;

  String? get pendingSignupName => _pendingSignupName;
  String? get pendingSignupEmail => _pendingSignupEmail;
  DateTime? get pendingSignupRequestedAt => _pendingSignupRequestedAt;
  bool get hasPendingSignup =>
      _pendingSignupName != null &&
      _pendingSignupEmail != null &&
      _pendingSignupOtp != null;

  Future<bool> login({required String email, required String password}) async {
    _startAction();
    try {
      _currentUser = await _authRepository.login(
        email: email.trim(),
        password: password,
      );
      await _syncPersistedSession(_currentUser);
      _markSessionBootstrapComplete();
      return true;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _endAction();
    }
  }

  Future<bool> loginWithGoogle({AppUserRole? roleForNewUser}) async {
    _startAction();
    try {
      _currentUser = await _authRepository.loginWithGoogle(
        roleForNewUser: roleForNewUser,
      );
      await _syncPersistedSession(_currentUser);
      _markSessionBootstrapComplete();
      return true;
    } on RoleSelectionRequiredException {
      _requiresRoleSelection = true;
      _errorMessage = 'Please choose a role to continue with Google.';
      return false;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _endAction();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required AppUserRole role,
  }) async {
    _startAction();
    try {
      await _authRepository.register(
        name: name.trim(),
        email: email.trim(),
        password: password,
        role: role,
      );
      await _authRepository.logout();
      _currentUser = null;
      await _clearPersistedSession();
      _markSessionBootstrapComplete();
      return true;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _endAction();
    }
  }

  Future<void> logout() async {
    _startAction();
    try {
      final userId = _currentUser?.id;
      await _authRepository.logout();
      _currentUser = null;
      await _clearPersistedSession();
      _markSessionBootstrapComplete();

      // ✅ Clear user-scoped data from AppState
      // This is a bit hacky but necessary to clear before navigating away
      // In a real app, you might use Provider to get this
      if (userId != null) {
        // Will be cleared when AppStateProvider.loadForUser('guest') is called
        // This should happen in the app initialization after logout
      }
    } catch (error) {
      _errorMessage = _friendlyError(error);
    } finally {
      _endAction();
    }
  }

  // Legacy OTP flow kept for compatibility with previous screens.
  Future<bool> requestSignupOtp({
    required String name,
    required String email,
  }) async {
    _startAction();
    try {
      final trimmedName = name.trim();
      final trimmedEmail = email.trim().toLowerCase();
      if (trimmedName.isEmpty || trimmedEmail.isEmpty) {
        _errorMessage = 'Name and email are required.';
        return false;
      }
      _pendingSignupName = trimmedName;
      _pendingSignupEmail = trimmedEmail;
      _pendingSignupOtp = '1234';
      _pendingSignupRequestedAt = DateTime.now();
      return true;
    } finally {
      _endAction();
    }
  }

  Future<bool> resendSignupOtp() async {
    final name = _pendingSignupName;
    final email = _pendingSignupEmail;
    if (name == null || email == null) {
      _errorMessage = 'No pending signup request was found.';
      notifyListeners();
      return false;
    }
    return requestSignupOtp(name: name, email: email);
  }

  Future<bool> verifySignupOtp(String code) async {
    final expected = _pendingSignupOtp;
    if (expected == null || code.trim() != expected) {
      _errorMessage = 'Invalid verification code.';
      notifyListeners();
      return false;
    }
    _pendingSignupName = null;
    _pendingSignupEmail = null;
    _pendingSignupOtp = null;
    _pendingSignupRequestedAt = null;
    notifyListeners();
    return true;
  }

  // ==================== OTP-based Password Reset ====================

  /// Send OTP code to email for password reset
  Future<bool> sendPasswordResetOtp(String email) async {
    _startAction();
    try {
      if (email.trim().isEmpty) {
        _errorMessage = 'Email is required.';
        return false;
      }

      // Cast to get access to the generateAndSendPasswordResetOtp method
      final repo = _authRepository as dynamic;
      final otp = await repo
          .generateAndSendPasswordResetOtp(email: email.trim())
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException(AuthConstants.timeoutErrorMessage);
            },
          );

      // Store pending reset data
      _pendingSignupEmail = email.trim();
      _pendingSignupOtp = otp;
      _pendingSignupRequestedAt = DateTime.now();

      return true;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _endAction();
    }
  }

  /// Verify OTP code
  Future<bool> verifyPasswordResetOtp(String email, String otp) async {
    _startAction();
    try {
      if (email.trim().isEmpty || otp.trim().isEmpty) {
        _errorMessage = 'Email and OTP are required.';
        return false;
      }

      final repo = _authRepository as dynamic;
      final verified = await repo
          .verifyPasswordResetOtp(email: email.trim(), otp: otp.trim())
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException(AuthConstants.timeoutErrorMessage);
            },
          );

      return verified;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _endAction();
    }
  }

  /// Reset password after OTP verification
  Future<bool> resetPasswordWithOtp({
    required String email,
    required String newPassword,
  }) async {
    _startAction();
    try {
      if (newPassword.length < AuthConstants.minPasswordLength) {
        _errorMessage =
            'Password must be at least ${AuthConstants.minPasswordLength} characters.';
        return false;
      }

      final repo = _authRepository as dynamic;
      await repo
          .resetPasswordWithOtp(email: email.trim(), newPassword: newPassword)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException(AuthConstants.timeoutErrorMessage);
            },
          );

      // Clear pending data
      _pendingSignupEmail = null;
      _pendingSignupOtp = null;
      _pendingSignupRequestedAt = null;

      return true;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _endAction();
    }
  }

  // ==================== Firebase Email Reset ====================

  Future<bool> requestPasswordReset(String email) async {
    _startAction();
    try {
      if (email.trim().isEmpty) {
        _errorMessage = 'Email is required.';
        return false;
      }

      final success = await _authRepository
          .sendPasswordResetEmail(email: email.trim())
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException(AuthConstants.timeoutErrorMessage);
            },
          );

      return success;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _endAction();
    }
  }

  Future<bool> resetPasswordWithCode({
    required String oobCode,
    required String newPassword,
  }) async {
    _startAction();
    try {
      if (newPassword.length < AuthConstants.minPasswordLength) {
        _errorMessage =
            'Password must be at least ${AuthConstants.minPasswordLength} characters.';
        return false;
      }

      await _authRepository
          .resetPasswordWithCode(oobCode: oobCode, newPassword: newPassword)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException(AuthConstants.timeoutErrorMessage);
            },
          );

      return true;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _endAction();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _startAction();
    try {
      if (currentPassword.length < AuthConstants.minPasswordLength ||
          newPassword.length < AuthConstants.minPasswordLength) {
        _errorMessage =
            'Password must be at least ${AuthConstants.minPasswordLength} characters.';
        return false;
      }
      return true;
    } finally {
      _endAction();
    }
  }

  Future<bool> updateProfile({
    required String name,
    String? phone,
    String? photoUrl,
  }) async {
    final user = _currentUser;
    if (user == null) {
      _errorMessage = 'No active user session.';
      notifyListeners();
      return false;
    }

    _startAction();
    try {
      final updated = await _authRepository.updateProfile(
        name: name.trim(),
        email: user.email,
        role: user.role,
        phone: phone?.trim(),
        photoUrl: photoUrl?.trim(),
      );
      _currentUser = updated;
      await _syncPersistedSession(updated);
      return true;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _endAction();
    }
  }

  void updateDisplayName(String name) {
    final user = _currentUser;
    if (user == null) return;
    _currentUser = user.copyWith(name: name.trim());
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _requiresRoleSelection = false;
    notifyListeners();
  }

  String maskEmail(String value) {
    final trimmed = value.trim();
    final atIndex = trimmed.indexOf('@');
    if (atIndex <= 1) return trimmed;
    final prefix = trimmed.substring(0, atIndex);
    final domain = trimmed.substring(atIndex);
    if (prefix.length <= 2) return '${prefix[0]}*$domain';
    final stars = List<String>.filled(prefix.length - 2, '*').join();
    return '${prefix[0]}$stars${prefix[prefix.length - 1]}$domain';
  }

  String _friendlyError(Object error) {
    return AppErrorMapper.auth(error);
  }

  void _startAction() {
    _isLoading = true;
    _errorMessage = null;
    _requiresRoleSelection = false;
    notifyListeners();
  }

  void _endAction() {
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _hydratePreferencesCache() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> _preferences() async {
    final cached = _prefs;
    if (cached != null) {
      return cached;
    }
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    return prefs;
  }

  Future<void> _syncPersistedSession(AppUser? user) async {
    if (user == null) {
      await _clearPersistedSession();
      return;
    }

    final prefs = await _preferences();
    final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
    final existingToken = prefs.getString(AuthConstants.tokenKey)?.trim() ?? '';

    var token = existingToken;
    try {
      final resolvedToken = await firebaseUser?.getIdToken();
      if (resolvedToken != null && resolvedToken.trim().isNotEmpty) {
        token = resolvedToken.trim();
      }
    } catch (_) {
      // Keep the previous token if Firebase returns a transient error.
    }

    if (token.isNotEmpty) {
      await prefs.setString(AuthConstants.tokenKey, token);
    }

    await prefs.setString(
      AuthConstants.userKey,
      jsonEncode(<String, dynamic>{
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'role': user.role.value,
        'phone': user.phone,
        'photoUrl': user.photoUrl,
      }),
    );
  }

  Future<void> _clearPersistedSession() async {
    final prefs = await _preferences();
    await prefs.remove(AuthConstants.tokenKey);
    await prefs.remove(AuthConstants.refreshTokenKey);
    await prefs.remove(AuthConstants.userKey);
  }

  void _markSessionBootstrapComplete() {
    if (_isSessionBootstrapping) {
      _isSessionBootstrapping = false;
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
