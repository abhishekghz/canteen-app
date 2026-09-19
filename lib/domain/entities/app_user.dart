enum UserRole { student, admin }

class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  bool get isAdmin => role == UserRole.admin;

  AppUser copyWith({String? name, String? email, UserRole? role}) => AppUser(
        uid: uid,
        name: name ?? this.name,
        email: email ?? this.email,
        role: role ?? this.role,
      );

  @override
  bool operator ==(Object other) =>
      other is AppUser && other.uid == uid && other.role == role;

  @override
  int get hashCode => Object.hash(uid, role);
}
