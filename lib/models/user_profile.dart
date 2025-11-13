class UserProfile {
  final int? id;
  final String name;
  final String gender; // 'Female' | 'Male' | 'Unisex'
  final String morphology; // e.g. 'Rectangle', 'Oval'
  final String season; // e.g. 'Summer', 'Winter'
  final String? avatarPath;

  const UserProfile({
    this.id,
    required this.name,
    required this.gender,
    required this.morphology,
    required this.season,
    this.avatarPath,
  });

  UserProfile copyWith({
    int? id,
    String? name,
    String? gender,
    String? morphology,
    String? season,
    String? avatarPath,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      morphology: morphology ?? this.morphology,
      season: season ?? this.season,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'morphology': morphology,
      'season': season,
      'avatarPath': avatarPath,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      name: map['name'] as String,
      gender: map['gender'] as String,
      morphology: map['morphology'] as String,
      season: map['season'] as String,
      avatarPath: map['avatarPath'] as String?,
    );
  }
}
