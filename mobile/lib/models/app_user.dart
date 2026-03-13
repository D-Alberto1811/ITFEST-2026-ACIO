class AppUser {
  final int? id;
  final String name;
  final String email;
  final String passwordHash;
  final String authProvider;
  final String? googleId;
  final String createdAt;

  const AppUser({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.authProvider,
    this.googleId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password_hash': passwordHash,
      'auth_provider': authProvider,
      'google_id': googleId,
      'created_at': createdAt,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      passwordHash: map['password_hash'] as String? ?? '',
      authProvider: map['auth_provider'] as String? ?? 'local',
      googleId: map['google_id'] as String?,
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  AppUser copyWith({
    int? id,
    String? name,
    String? email,
    String? passwordHash,
    String? authProvider,
    String? googleId,
    String? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      authProvider: authProvider ?? this.authProvider,
      googleId: googleId ?? this.googleId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}