class User {
  final String id;
  final String username;
  final String name;
  final String email;
  final UserRole role;

  User({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.role,
  });
}

enum UserRole {
  student,
  admin,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.admin:
        return 'Admin';
    }
  }
}
