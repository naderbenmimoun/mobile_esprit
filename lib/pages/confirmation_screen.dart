import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import '../services/pdf_generator.dart';
import '../models/order.dart';
import '../services/db_help.dart';

class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({super.key});

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  final DBHelper _db = DBHelper.instance;
  Order? currentOrder;
  List<Map<String, dynamic>> orderItems = [];
  double orderTotal = 0.0;
  int? orderId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    orderId = args?['orderId'] as int?;
    if (orderId != null) {
      _loadOrder(orderId!);
    }
  }

  Future<void> _loadOrder(int id) async {
    try {
      final order = await _db.getOrderById(id);
      if (order == null) {
        throw Exception('Commande non trouvée');
      }

      final items = await _db.getOrderItems(id);

      setState(() {
        currentOrder = order;
        orderItems = items;
        orderTotal = order.total;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement de la commande: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy HH:mm').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  String _formatAdresse(String? jsonStr) {
    if (jsonStr == null) return 'Non spécifiée';
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return '''
${map['nom'] ?? ''}
${map['adresse'] ?? ''}
${map['cp'] ?? ''} ${map['ville'] ?? ''}
''';
    } catch (e) {
      return jsonStr;
    }
  }

  Future<void> _generateAndSharePDF(BuildContext context) async {
    if (currentOrder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Données de commande non disponibles'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await PdfGenerator.generateOrderPdf(
        order: currentOrder!,
        orderItems: orderItems,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération du PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (currentOrder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Confirmation')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Text('Confirmation'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _generateAndSharePDF(context),
            tooltip: 'Générer la facture',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green[600],
              size: 100,
            ),
            const SizedBox(height: 20),
            Text(
              'Paiement réussi 🎉',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Merci pour votre achat ! Votre commande est en route 🚚',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 30),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Détails de la commande',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'N° Commande',
                      value: currentOrder!.numeroCommande ??
                          'CMD-${DateTime.now().millisecondsSinceEpoch}',
                    ),
                    _DetailRow(
                      label: 'Date',
                      value: _formatDate(currentOrder!.date),
                    ),
                    _DetailRow(
                      label: 'Statut',
                      value: currentOrder!.status,
                    ),
                    _DetailRow(
                      label: 'Mode de paiement',
                      value: currentOrder!.modePaiement,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (currentOrder!.adresseJson != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Adresse de livraison',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_formatAdresse(currentOrder!.adresseJson)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Articles',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...orderItems.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item['nom']} (x${item['qty']})'),
                              Text(
                                '${(item['prix'] * item['qty']).toStringAsFixed(2)}€',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${currentOrder!.total.toStringAsFixed(2)}€',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Scanner pour voir les détails',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: jsonEncode({
                          'orderId': currentOrder!.id,
                          'numeroCommande': currentOrder!.numeroCommande,
                          'date': currentOrder!.date,
                          'total': currentOrder!.total,
                          'status': currentOrder!.status,
                          'modePaiement': currentOrder!.modePaiement,
                          'adresse': currentOrder!.adresseJson,
                          'items': orderItems,
                        }),
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _generateAndSharePDF(context),
                      icon: const Icon(Icons.download),
                      label: const Text('Télécharger la facture'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
