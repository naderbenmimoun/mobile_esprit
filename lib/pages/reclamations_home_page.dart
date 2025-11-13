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
      // Cleanup legacy static rows (from older versions without userId)
      await ReclamationDatabase.instance.deleteLegacyWithoutUserId();

      final items = await ReclamationDatabase.instance.readAll();
      debugPrint('📊 Nombre de réclamations dans SQLite: ${items.length}');
      setState(() {
        reclamations = items;
        _isLoading = false;
      });
      debugPrint('✅ ${items.length} réclamations chargées');
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement: $e');
      setState(() => _isLoading = false);
    }
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
