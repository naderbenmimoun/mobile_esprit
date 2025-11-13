class Favorite {
  final int? id;
  final String outfitId; // Référence à Outfit
  final DateTime addedAt;

  Favorite({
    this.id,
    required this.outfitId,
    required this.addedAt,
  });

  // ✅ Convertir en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'outfitId': outfitId,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  // ✅ Créer depuis Map (lecture SQLite)
  factory Favorite.fromMap(Map<String, dynamic> map) {
    return Favorite(
      id: map['id'] as int?,
      outfitId: map['outfitId'] as String,
      addedAt: DateTime.parse(map['addedAt'] as String),
    );
  }
}
