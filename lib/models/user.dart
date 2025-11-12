class AppUser {
  final int? id;
  final String name;
  final String email;
  final String passwordHash; // SHA-256
  final String role; // 'admin' | 'client'
  final String? imageUrl;
  final String gender; // 'Male' | 'Female' | 'Unisex'
  final String morphology; // 'Oval' | 'Rectangle' | 'Triangle' | 'Hourglass' | 'Pear'
  final String? couponCode; // optional coupon assigned at signup

  const AppUser({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.role,
    this.imageUrl,
    required this.gender,
    required this.morphology,
    this.couponCode,
  });

  AppUser copyWith({
    int? id,
    String? name,
    String? email,
    String? passwordHash,
    String? role,
    String? imageUrl,
    String? gender,
    String? morphology,
    String? couponCode,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      imageUrl: imageUrl ?? this.imageUrl,
      gender: gender ?? this.gender,
      morphology: morphology ?? this.morphology,
      couponCode: couponCode ?? this.couponCode,
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
      'gender': gender,
      'morphology': morphology,
      'coupon_code': couponCode,
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
      gender: (map['gender'] as String?) ?? 'Unisex',
      morphology: (map['morphology'] as String?) ?? 'Oval',
      couponCode: map['coupon_code'] as String?,
    );
  }
}
