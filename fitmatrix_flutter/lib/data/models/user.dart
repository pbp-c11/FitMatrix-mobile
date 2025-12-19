class User {
  final int id;
  final String username;
  final String email;
  final String displayName;
  final String role;
  final bool isAdmin;
  final String? avatar;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isAdmin,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        username: json['username'] as String? ?? '',
        email: json['email'] as String? ?? '',
        displayName: json['display_name'] as String? ?? '',
        role: json['role'] as String? ?? 'USER',
        isAdmin: json['is_admin'] as bool? ?? false,
        avatar: json['avatar'] as String?,
      );
}
