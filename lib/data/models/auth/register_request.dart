import '../../../domain/entities/app_user.dart';

class RegisterRequest {
  final String name;
  final String email;
  final String password;
  final AppUserRole role;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'password': password,
    'role': role.toString().split('.').last,
  };

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      RegisterRequest(
        name: json['name'] as String,
        email: json['email'] as String,
        password: json['password'] as String,
        role: AppUserRole.values.firstWhere(
          (role) => role.toString().split('.').last == json['role'],
        ),
      );
}
