import '../../../domain/entities/app_user.dart';

class AuthResponse {
  final AppUser user;
  final String token;
  final String? refreshToken;

  AuthResponse({required this.user, required this.token, this.refreshToken});

  Map<String, dynamic> toJson() => {
    'user': user,
    'token': token,
    'refreshToken': refreshToken,
  };

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    user: json['user'] as AppUser,
    token: json['token'] as String,
    refreshToken: json['refreshToken'] as String?,
  );
}
