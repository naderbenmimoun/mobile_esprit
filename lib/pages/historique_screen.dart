import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/db_help.dart';
import '../models/order.dart';

class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  late Future<List<Order>> _futureOrders;

  @override
  void initState() {
    super.initState();
    _futureOrders = DBHelper.instance.getAllOrders();
  }

  String _formatTotal(double total) => "${total.toStringAsFixed(2)} €";
  String _formatDate(String d) {
    try {
      final dt = DateTime.parse(d.replaceFirst(' ', 'T'));
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {
      return d;
    }
  }

  String _shortAddress(String? adresseJson) {
    if (adresseJson == null) return "";
    try {
      final map = jsonDecode(adresseJson) as Map<String, dynamic>;
      final nom = map['nom'];
      final ville = map['ville'];
      final cp = map['cp'];
      final lat = map['lat'];
      final lng = map['lng'];
      if (ville != null && cp != null) return "$ville $cp";
      if (lat != null && lng != null) return "(${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})";
      return nom?.toString() ?? "";
    } catch (_) {
      return "";
    }
  }

  Color _statusColor(BuildContext context, String s) {
    final c = Theme.of(context).colorScheme;
    switch (s) {
      case 'livree':
        return Colors.green;
      case 'en_attente':
        return c.primary;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des commandes'),
      ),
      body: FutureBuilder<List<Order>>(
        future: _futureOrders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('Aucune commande'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final o = orders[index];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                    child: const Icon(Icons.receipt_long),
                  ),
                  title: Text(_formatTotal(o.total), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(_formatDate(o.date)),
                      if ((o.adresseJson ?? '').isNotEmpty) Text(_shortAddress(o.adresseJson)),
                    ],
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(o.numeroCommande ?? '', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(context, o.status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(o.status, style: theme.textTheme.labelSmall?.copyWith(color: _statusColor(context, o.status))),
                      ),
                    ],
                  ),
                  onTap: () async {
                    final items = await DBHelper.instance.getOrderItems(o.id!);
                    if (!mounted) return;
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                      builder: (_) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Commande ${o.numeroCommande ?? ''}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(_formatDate(o.date)),
                              if ((o.adresseJson ?? '').isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(_shortAddress(o.adresseJson)),
                              ],
                              const SizedBox(height: 12),
                              ...items.map((it) => ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(it['nom']?.toString() ?? ''),
                                    trailing: Text("${(it['prix'] as num).toStringAsFixed(2)} × ${it['qty']}"),
                                  )),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(_formatTotal(o.total), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
