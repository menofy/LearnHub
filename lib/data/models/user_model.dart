import '../../domain/entities/app_user.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role = AppUserRole.student,
    this.phone = '',
    this.photoUrl = '',
  });

  final String id;
  final String name;
  final String email;
  final AppUserRole role;
  final String phone;
  final String photoUrl;

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: _asString(map['uid'] ?? map['id']),
      name: _asString(map['name']),
      email: _asString(map['email']),
      role: AppUserRoleX.fromValue(map['role'] as String?),
      phone: _asString(map['phone'] ?? map['phoneNumber']),
      photoUrl: _asString(map['image'] ?? map['photoUrl']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'name': name,
      'email': email,
      'role': role.value,
      'phone': phone,
      'image': photoUrl,
    };
  }

  AppUser toEntity() {
    return AppUser(
      id: id,
      name: name,
      email: email,
      role: role,
      phone: phone,
      photoUrl: photoUrl,
    );
  }

  factory UserModel.fromEntity(AppUser user) {
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      phone: user.phone,
      photoUrl: user.photoUrl,
    );
  }

  static String _asString(Object? value) {
    if (value is String) {
      return value;
    }
    if (value == null) {
      return '';
    }
    return value.toString();
  }
}
