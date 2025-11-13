class TryOnHistory {
  final int? id;
  final String outfitId; // Référence à Outfit
  final String userImagePath; // Photo de l'utilisateur
  final String? generatedImagePath; // Résultat du try-on (optionnel si échec)
  final DateTime triedAt;

  TryOnHistory({
    this.id,
    required this.outfitId,
    required this.userImagePath,
    this.generatedImagePath,
    required this.triedAt,
  });

  // ✅ Convertir en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'outfitId': outfitId,
      'userImagePath': userImagePath,
      'generatedImagePath': generatedImagePath,
      'triedAt': triedAt.toIso8601String(),
    };
  }

  // ✅ Créer depuis Map (lecture SQLite)
  factory TryOnHistory.fromMap(Map<String, dynamic> map) {
    return TryOnHistory(
      id: map['id'] as int?,
      outfitId: map['outfitId'] as String,
      userImagePath: map['userImagePath'] as String,
      generatedImagePath: map['generatedImagePath'] as String?,
      triedAt: DateTime.parse(map['triedAt'] as String),
    );
  }
}
