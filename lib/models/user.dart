class AppUser {
  final int? id;
  final String name;
  final String email;
  final String passwordHash; // SHA-256
  final String role; // 'admin' | 'client'
  final String? imageUrl;

  const AppUser({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.role,
    this.imageUrl,
  });

  AppUser copyWith({
    int? id,
    String? name,
    String? email,
    String? passwordHash,
    String? role,
    String? imageUrl,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password_hash': passwordHash,
      'role': role,
      'image_url': imageUrl,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      role: map['role'] as String,
      imageUrl: map['image_url'] as String?,
    );
  }
}
