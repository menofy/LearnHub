import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
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
        if (_shouldEndEphemeralSession(user)) {
          unawaited(_expireEphemeralSession());
          return;
        }
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
  final LocalAuthentication _localAuth = LocalAuthentication();
  StreamSubscription<AppUser?>? _authSub;
  SharedPreferences? _prefs;
  bool _isSessionBootstrapping = true;
  bool _isEndingEphemeralSession = false;

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _statusMessage;
  bool _requiresRoleSelection = false;
  bool _rememberMeEnabled = true;
  bool _biometricEnabled = false;
  bool _faceIdEnabled = false;
  bool _hasPinConfigured = false;
  bool _ephemeralSessionActive = false;
  PasswordResetOtpResult? _lastPasswordResetOtpResult;

  String? _pendingSignupName;
  String? _pendingSignupEmail;
  String? _pendingSignupOtp;
  DateTime? _pendingSignupRequestedAt;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isSessionBootstrapping => _isSessionBootstrapping;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;
  bool get requiresRoleSelection => _requiresRoleSelection;
  bool get rememberMeEnabled => _rememberMeEnabled;
  bool get biometricEnabled => _biometricEnabled;
  bool get faceIdEnabled => _faceIdEnabled;
  bool get hasPinConfigured => _hasPinConfigured;
  PasswordResetOtpResult? get lastPasswordResetOtpResult =>
      _lastPasswordResetOtpResult;

  String? get pendingSignupName => _pendingSignupName;
  String? get pendingSignupEmail => _pendingSignupEmail;
  DateTime? get pendingSignupRequestedAt => _pendingSignupRequestedAt;
  bool get hasPendingSignup =>
      _pendingSignupName != null &&
      _pendingSignupEmail != null &&
      _pendingSignupOtp != null;

  Future<bool> login({
    required String email,
    required String password,
    bool? rememberMe,
  }) async {
    _startAction();
    try {
      final rememberChoice = rememberMe ?? _rememberMeEnabled;
      await _setRememberMeEnabledInternal(rememberChoice);
      _currentUser = await _authRepository.login(
        email: email.trim(),
        password: password,
      );
      await _setEphemeralSessionActive(!rememberChoice);
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

  Future<bool> loginWithGoogle({
    AppUserRole? roleForNewUser,
    bool? rememberMe,
  }) async {
    _startAction();
    try {
      final rememberChoice = rememberMe ?? _rememberMeEnabled;
      await _setRememberMeEnabledInternal(rememberChoice);
      _currentUser = await _authRepository.loginWithGoogle(
        roleForNewUser: roleForNewUser,
      );
      await _setEphemeralSessionActive(!rememberChoice);
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
      await _setEphemeralSessionActive(false);
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
      await _setEphemeralSessionActive(false);
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

      final otp = await _authRepository
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

      final verified = await _authRepository
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

      final result = await _authRepository
          .resetPasswordWithOtp(email: email.trim(), newPassword: newPassword)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException(AuthConstants.timeoutErrorMessage);
            },
          );

      _lastPasswordResetOtpResult = result;
      _statusMessage = switch (result) {
        PasswordResetOtpResult.passwordUpdated =>
          'Your password has been updated successfully.',
        PasswordResetOtpResult.resetLinkSent =>
          'OTP verified. A secure reset link has been sent to your email to finish updating your password.',
      };

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
      if (_currentUser == null) {
        _errorMessage = 'No active user session.';
        return false;
      }
      if (currentPassword.length < AuthConstants.minPasswordLength ||
          newPassword.length < AuthConstants.minPasswordLength) {
        _errorMessage =
            'Password must be at least ${AuthConstants.minPasswordLength} characters.';
        return false;
      }
      if (currentPassword == newPassword) {
        _errorMessage =
            'Choose a new password that is different from your current password.';
        return false;
      }
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _statusMessage = AuthConstants.passwordChangedMessage;
      return true;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _endAction();
    }
  }

  Future<void> setRememberMeEnabled(bool value) async {
    await _setRememberMeEnabledInternal(value);
    if (value) {
      await _setEphemeralSessionActive(false);
      await _syncPersistedSession(_currentUser);
    } else if (_currentUser != null) {
      await _setEphemeralSessionActive(true);
      await _clearPersistedSession();
    }
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    final prefs = await _preferences();
    _biometricEnabled = value;
    await prefs.setBool(AuthConstants.biometricEnabledKey, value);
    if (!value && _faceIdEnabled) {
      _faceIdEnabled = false;
      await prefs.setBool(AuthConstants.faceIdEnabledKey, false);
    }
    notifyListeners();
  }

  /// Verify identity using biometric for sensitive operations
  Future<bool> verifyWithBiometric({required String reason}) async {
    try {
      if (!_biometricEnabled) {
        return false;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      return didAuthenticate;
    } catch (_) {
      return false;
    }
  }

  Future<void> setFaceIdEnabled(bool value) async {
    final prefs = await _preferences();
    _faceIdEnabled = value;
    await prefs.setBool(AuthConstants.faceIdEnabledKey, value);
    if (value && !_biometricEnabled) {
      _biometricEnabled = true;
      await prefs.setBool(AuthConstants.biometricEnabledKey, true);
    }
    notifyListeners();
  }

  Future<bool> savePin({String? currentPin, required String newPin}) async {
    final normalizedPin = newPin.trim();
    final existingHash = await _getStoredPinHash();

    if (!_isValidPin(normalizedPin)) {
      _errorMessage = 'PIN must be exactly ${AuthConstants.pinLength} digits.';
      notifyListeners();
      return false;
    }

    if (existingHash != null) {
      final normalizedCurrentPin = currentPin?.trim() ?? '';
      if (!_isValidPin(normalizedCurrentPin)) {
        _errorMessage = 'Enter your current PIN to continue.';
        notifyListeners();
        return false;
      }
      if (_hashPin(normalizedCurrentPin) != existingHash) {
        _errorMessage = 'Current PIN is incorrect.';
        notifyListeners();
        return false;
      }
    }

    final prefs = await _preferences();
    await prefs.setString(AuthConstants.pinHashKey, _hashPin(normalizedPin));
    _hasPinConfigured = true;
    _errorMessage = null;
    _statusMessage = existingHash == null
        ? 'PIN created successfully.'
        : 'PIN updated successfully.';
    notifyListeners();
    return true;
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
    _statusMessage = null;
    _requiresRoleSelection = false;
    _lastPasswordResetOtpResult = null;
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
    _statusMessage = null;
    _requiresRoleSelection = false;
    _lastPasswordResetOtpResult = null;
    notifyListeners();
  }

  void _endAction() {
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _hydratePreferencesCache() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    _rememberMeEnabled = prefs.getBool(AuthConstants.rememberMeKey) ?? true;
    _biometricEnabled =
        prefs.getBool(AuthConstants.biometricEnabledKey) ?? false;
    _faceIdEnabled = prefs.getBool(AuthConstants.faceIdEnabledKey) ?? false;
    _hasPinConfigured =
        (prefs.getString(AuthConstants.pinHashKey)?.trim().isNotEmpty ?? false);
    _ephemeralSessionActive =
        prefs.getBool(AuthConstants.ephemeralSessionKey) ?? false;
    notifyListeners();
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

    if (!_rememberMeEnabled) {
      await _clearPersistedSession();
      return;
    }

    final prefs = await _preferences();
    final existingToken = prefs.getString(AuthConstants.tokenKey)?.trim() ?? '';
    var token = existingToken;
    final resolvedToken = await _resolveFirebaseToken();
    if (resolvedToken != null && resolvedToken.isNotEmpty) {
      token = resolvedToken;
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

  Future<String?> _resolveFirebaseToken() async {
    try {
      final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
      final resolvedToken = await firebaseUser?.getIdToken();
      if (resolvedToken == null) {
        return null;
      }
      final trimmed = resolvedToken.trim();
      return trimmed.isEmpty ? null : trimmed;
    } catch (_) {
      // Keep the existing local token when Firebase Auth is unavailable.
      return null;
    }
  }

  Future<void> _clearPersistedSession() async {
    final prefs = await _preferences();
    await prefs.remove(AuthConstants.tokenKey);
    await prefs.remove(AuthConstants.refreshTokenKey);
    await prefs.remove(AuthConstants.userKey);
  }

  Future<void> _setRememberMeEnabledInternal(bool value) async {
    _rememberMeEnabled = value;
    final prefs = await _preferences();
    await prefs.setBool(AuthConstants.rememberMeKey, value);
  }

  Future<void> _setEphemeralSessionActive(bool value) async {
    _ephemeralSessionActive = value;
    final prefs = await _preferences();
    await prefs.setBool(AuthConstants.ephemeralSessionKey, value);
  }

  bool _shouldEndEphemeralSession(AppUser? user) {
    return !_isEndingEphemeralSession &&
        _isSessionBootstrapping &&
        _ephemeralSessionActive &&
        user != null;
  }

  Future<void> _expireEphemeralSession() async {
    if (_isEndingEphemeralSession) {
      return;
    }

    _isEndingEphemeralSession = true;
    try {
      await _authRepository.logout();
      _currentUser = null;
      await _setEphemeralSessionActive(false);
      await _clearPersistedSession();
    } catch (error) {
      _errorMessage = _friendlyError(error);
    } finally {
      _isEndingEphemeralSession = false;
      _markSessionBootstrapComplete();
      notifyListeners();
    }
  }

  Future<String?> _getStoredPinHash() async {
    final prefs = await _preferences();
    final stored = prefs.getString(AuthConstants.pinHashKey)?.trim();
    if (stored == null || stored.isEmpty) {
      return null;
    }
    return stored;
  }

  bool _isValidPin(String value) {
    final regex = RegExp('^\\d{${AuthConstants.pinLength}}\$');
    return regex.hasMatch(value.trim());
  }

  String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin.trim())).toString();
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
