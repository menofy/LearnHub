/// Constants for authentication
class AuthConstants {
  // HTTP Headers
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer';
  static const String contentTypeHeader = 'Content-Type';
  static const String contentTypeJson = 'application/json';

  // Token keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'current_user';
  static const String rememberMeKey = 'remember_me_enabled';
  static const String ephemeralSessionKey = 'ephemeral_session_active';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String faceIdEnabledKey = 'face_id_enabled';
  static const String pinHashKey = 'security_pin_hash';

  // OTP
  static const int otpLength = 6;
  static const int otpExpirationMinutes = 10;
  static const int otpMaxRetries = 3;

  // PIN
  static const int pinLength = 4;

  // Password
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;

  // Session timeout
  static const Duration sessionTimeout = Duration(minutes: 30);
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);

  // API endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String googleLoginEndpoint = '/api/auth/google-login';
  static const String logoutEndpoint = '/api/auth/logout';
  static const String refreshTokenEndpoint = '/api/auth/refresh-token';
  static const String verifyEmailEndpoint = '/api/auth/verify-email';
  static const String resendOtpEndpoint = '/api/auth/resend-otp';
  static const String setFingerprint = '/api/auth/set-fingerprint';
  static const String verifyFingerprint = '/api/auth/verify-fingerprint';

  // Error messages
  static const String genericErrorMessage =
      'An error occurred. Please try again.';
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
  static const String timeoutErrorMessage =
      'Request timed out. Please try again.';
  static const String invalidCredentialsMessage = 'Invalid email or password.';
  static const String userNotFoundMessage = 'User not found.';
  static const String userAlreadyExistsMessage =
      'User with this email already exists.';
  static const String emailNotVerifiedMessage =
      'Please verify your email before proceeding.';
  static const String sessionExpiredMessage =
      'Your session has expired. Please login again.';

  // Success messages
  static const String loginSuccessMessage = 'Login successful';
  static const String registerSuccessMessage = 'Registration successful';
  static const String logoutSuccessMessage = 'Logout successful';
  static const String emailVerifiedMessage = 'Email verified successfully';
  static const String passwordChangedMessage = 'Password changed successfully';
  static const String profileUpdatedMessage = 'Profile updated successfully';
}
