class Outfit {
  final String id;
  final String name;
  final String imagePath;
  final double price;
  final String gender; // 'Female' | 'Male' | 'Unisex'
  final List<String> morphologies; // e.g. ['Rectangle','Oval']
  final List<String> seasons; // e.g. ['Summer','Winter']
  final double matchScore;

  const Outfit({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.price,
    required this.gender,
    required this.morphologies,
    required this.seasons,
    required this.matchScore,
  });

  Outfit copyWith({
    String? id,
    String? name,
    String? imagePath,
    double? price,
    String? gender,
    List<String>? morphologies,
    List<String>? seasons,
    double? matchScore,
  }) {
    return Outfit(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      price: price ?? this.price,
      gender: gender ?? this.gender,
      morphologies: morphologies ?? this.morphologies,
      seasons: seasons ?? this.seasons,
      matchScore: matchScore ?? this.matchScore,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'price': price,
      'gender': gender,
      'morphologies': morphologies.join(','),
      'seasons': seasons.join(','),
      'matchScore': matchScore,
    };
  }

  factory Outfit.fromMap(Map<String, dynamic> map) {
    List<String> _split(String? s) {
      if (s == null || s.trim().isEmpty) return <String>[];
      return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    return Outfit(
      id: map['id'] as String,
      name: map['name'] as String,
      imagePath: map['imagePath'] as String,
      price: (map['price'] is int) ? (map['price'] as int).toDouble() : (map['price'] as num).toDouble(),
      gender: map['gender'] as String,
      morphologies: _split(map['morphologies'] as String?),
      seasons: _split(map['seasons'] as String?),
      matchScore: (map['matchScore'] is int)
          ? (map['matchScore'] as int).toDouble()
          : ((map['matchScore'] ?? 0.0) as num).toDouble(),
    );
  }
}
