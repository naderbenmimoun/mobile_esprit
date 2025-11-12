class Order {
  final int? id;
  final double total;
  final String date;
  final String? adresseJson;
  final String status;
  final String modePaiement;
  final String? numeroCommande;

  Order({
    this.id,
    required this.total,
    required this.date,
    this.adresseJson,
    this.status = 'en_attente',
    required this.modePaiement,
    this.numeroCommande,
  });

  static String getCurrentDateTime() {
    final now = DateTime.now().toUtc();
    return "${now.year}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')} "
        "${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}:"
        "${now.second.toString().padLeft(2, '0')}";
  }

  static String generateNumeroCommande() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch % 10000;
    return 'CMD${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}$timestamp';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'total': total,
        'date': date,
        'adresse': adresseJson,
        'status': status,
        'mode_paiement': modePaiement,
        'numero_commande': numeroCommande ?? generateNumeroCommande(),
      };

  factory Order.fromMap(Map<String, dynamic> map) => Order(
        id: map['id'] as int?,
        total: (map['total'] as num).toDouble(),
        date: map['date'] as String,
        adresseJson: map['adresse'] as String?,
        status: map['status'] as String? ?? 'en_attente',
        modePaiement: map['mode_paiement'] as String,
        numeroCommande: map['numero_commande'] as String?,
      );

  factory Order.create({
    required double total,
    required String modePaiement,
    String? adresseJson,
  }) {
    return Order(
      total: total,
      date: getCurrentDateTime(),
      adresseJson: adresseJson,
      modePaiement: modePaiement,
      status: 'en_attente',
      numeroCommande: generateNumeroCommande(),
    );
  }
}
