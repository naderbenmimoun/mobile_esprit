import 'dart:convert';

class Reclamation {
  final String id;
  final String titre;
  final String description;
  final String statut;
  final DateTime dateCreation;
  final List<String> attachments; // chemins locaux file://...

  Reclamation({
    required this.id,
    required this.titre,
    required this.description,
    required this.statut,
    required this.dateCreation,
    List<String>? attachments,
  }) : attachments = attachments ?? [];

  Reclamation copyWith({
    String? id,
    String? titre,
    String? description,
    String? statut,
    DateTime? dateCreation,
    List<String>? attachments,
  }) {
    return Reclamation(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      statut: statut ?? this.statut,
      dateCreation: dateCreation ?? this.dateCreation,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titre': titre,
      'description': description,
      'statut': statut,
      'dateCreation': dateCreation.toIso8601String(),
      'attachments': jsonEncode(attachments),
    };
  }

  factory Reclamation.fromMap(Map<String, dynamic> map) {
    final attachmentsJson = map['attachments'] as String? ?? '[]';
    List<dynamic> list = [];
    try {
      list = jsonDecode(attachmentsJson) as List<dynamic>;
    } catch (_) {
      list = [];
    }
    final attachmentsList = list.map((e) => e.toString()).toList();

    return Reclamation(
      id: map['id'] as String,
      titre: map['titre'] as String,
      description: map['description'] as String,
      statut: map['statut'] as String,
      dateCreation: DateTime.parse(map['dateCreation'] as String),
      attachments: attachmentsList,
    );
  }

  @override
  String toString() {
    return 'Reclamation(id: $id, titre: $titre, statut: $statut, dateCreation: $dateCreation, attachments: ${attachments.length})';
  }
}
