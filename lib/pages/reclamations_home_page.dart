import 'package:flutter/material.dart';
import '../models/reclamation.dart';
import '../services/reclamation_db.dart';
import 'reclamations_list_screen.dart';
import 'create_reclamation_screen.dart';

class ReclamationsHomePage extends StatefulWidget {
  const ReclamationsHomePage({super.key});

  @override
  State<ReclamationsHomePage> createState() => _ReclamationsHomePageState();
}

class _ReclamationsHomePageState extends State<ReclamationsHomePage> {
  List<Reclamation> reclamations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReclamations();
  }

  Future<void> _loadReclamations() async {
    debugPrint('🔄 Chargement des réclamations...');
    setState(() => _isLoading = true);
    try {
      final items = await ReclamationDatabase.instance.readAll();
      debugPrint('📊 Nombre de réclamations dans SQLite: ${items.length}');
      if (items.isEmpty) {
        debugPrint('🆕 Première utilisation - Insertion des données exemple');
        await _insertSampleData();
        final newItems = await ReclamationDatabase.instance.readAll();
        setState(() {
          reclamations = newItems;
          _isLoading = false;
        });
        debugPrint('✅ ${newItems.length} réclamations chargées');
      } else {
        setState(() {
          reclamations = items;
          _isLoading = false;
        });
        debugPrint('✅ ${items.length} réclamations chargées');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _insertSampleData() async {
    debugPrint('🔧 Insertion des données exemple...');
    final now = DateTime.now().millisecondsSinceEpoch;
    final samples = [
      Reclamation(
        id: now.toString(),
        titre: 'Produit cassé',
        description: 'Le produit reçu est cassé.',
        statut: 'Ouvert',
        dateCreation: DateTime.now(),
      ),
      Reclamation(
        id: (now + 1).toString(),
        titre: 'Colis non reçu',
        description: 'Je n\'ai pas reçu mon colis.',
        statut: 'En cours',
        dateCreation: DateTime.now(),
      ),
      Reclamation(
        id: (now + 2).toString(),
        titre: 'Article manquant',
        description: 'Un accessoire manquant dans la commande.',
        statut: 'Ouvert',
        dateCreation: DateTime.now(),
        attachments: const [],
      ),
    ];

    for (var rec in samples) {
      debugPrint('  ➕ Insertion: ${rec.titre}');
      await ReclamationDatabase.instance.create(rec);
    }
    debugPrint('✅ ${samples.length} réclamations insérées');
  }

  Future<void> _addReclamation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateReclamationScreen(),
      ),
    );

    if (result is Map<String, dynamic>) {
      final titre = result['titre'] as String? ?? '';
      final description = result['description'] as String? ?? '';
      final attachmentsDynamic = result['attachments'];
      List<String> attachments = [];
      if (attachmentsDynamic is List) {
        attachments = attachmentsDynamic.map((e) => e.toString()).toList();
      }
      try {
        final newRec = Reclamation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          titre: titre,
          description: description,
          statut: 'Ouvert',
          dateCreation: DateTime.now(),
          attachments: attachments,
        );
        await ReclamationDatabase.instance.create(newRec);
        await _loadReclamations();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Réclamation ajoutée avec succès'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ReclamationsListScreen(
      reclamations: reclamations,
      onAddPressed: _addReclamation,
    );
  }
}
