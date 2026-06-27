class UserSession {
  const UserSession({
    required this.id,
    required this.email,
    required this.displayName,
    required this.initials,
    required this.tier,
    required this.token,
    this.role = 'user',
  });

  final String id;
  final String email;
  final String displayName;
  final String initials;
  final String tier;
  final String token;
  final String role;

  bool get isAdmin => role == 'admin';

  factory UserSession.fromJson(
    Map<String, dynamic> json, {
    required String token,
  }) {
    return UserSession(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Nexus Member',
      initials: json['initials'] as String? ?? 'NX',
      tier: json['tier'] as String? ?? 'Member · Nova rewards tier',
      token: token,
      role: json['role'] as String? ?? 'user',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'initials': initials,
        'tier': tier,
        'role': role,
      };
}
