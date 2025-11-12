class Delivery {
  final int? id;
  final int? orderId;
  final String nom;
  final String adresse;
  final String ville;
  final String cp;
  final String? phone;
  final String? instructions;

  Delivery({
    this.id,
    this.orderId,
    required this.nom,
    required this.adresse,
    required this.ville,
    required this.cp,
    this.phone,
    this.instructions,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'orderId': orderId,
        'nom': nom,
        'adresse': adresse,
        'ville': ville,
        'cp': cp,
        'phone': phone,
        'instructions': instructions,
      };

  factory Delivery.fromMap(Map<String, dynamic> m) => Delivery(
        id: m['id'] as int?,
        orderId: m['orderId'] as int?,
        nom: m['nom'] as String,
        adresse: m['adresse'] as String,
        ville: m['ville'] as String,
        cp: m['cp'] as String,
        phone: m['phone'] as String?,
        instructions: m['instructions'] as String?,
      );
}
