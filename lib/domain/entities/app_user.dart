enum AppUserRole { student, instructor }

extension AppUserRoleX on AppUserRole {
  String get value => this == AppUserRole.instructor ? 'instructor' : 'student';

  static AppUserRole fromValue(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized == 'instructor') {
      return AppUserRole.instructor;
    }
    return AppUserRole.student;
  }
}

class AppUser {
  const AppUser({
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

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    AppUserRole? role,
    String? phone,
    String? photoUrl,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
