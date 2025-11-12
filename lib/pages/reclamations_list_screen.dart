import 'package:flutter/material.dart';
import '../models/reclamation.dart';
import '../services/reclamation_db.dart';
import '../widgets/reclamation_card.dart';
import 'reclamation_detail_screen.dart';

class ReclamationsListScreen extends StatefulWidget {
  final List<Reclamation> reclamations;
  final VoidCallback onAddPressed;

  const ReclamationsListScreen({
    Key? key,
    required this.reclamations,
    required this.onAddPressed,
  }) : super(key: key);

  @override
  State<ReclamationsListScreen> createState() => _ReclamationsListScreenState();
}

class _ReclamationsListScreenState extends State<ReclamationsListScreen> {
  String searchText = '';
  List<Reclamation> _localReclamations = [];

  @override
  void initState() {
    super.initState();
    _localReclamations = List.from(widget.reclamations);
  }

  @override
  void didUpdateWidget(ReclamationsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reclamations != widget.reclamations) {
      _localReclamations = List.from(widget.reclamations);
    }
  }

  Future<void> handleEdit(Reclamation updatedReclamation) async {
    await ReclamationDatabase.instance.update(updatedReclamation);
    await _refreshList();
  }

  Future<void> handleDelete(String id) async {
    await ReclamationDatabase.instance.delete(id);
    await _refreshList();
  }

  Future<void> _refreshList() async {
    final items = await ReclamationDatabase.instance.readAll();
    setState(() {
      _localReclamations = items;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredReclamations = _localReclamations.where((reclamation) {
      final query = searchText.toLowerCase();
      return reclamation.titre.toLowerCase().contains(query) ||
          reclamation.description.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("SmartFIT - Mes Réclamations"),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Assistant IA',
            icon: const Icon(Icons.smart_toy_outlined),
            onPressed: () => Navigator.pushNamed(context, '/chat'),
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).colorScheme.background,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: "Rechercher",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                  });
                },
              ),
            ),
            Expanded(
              child: filteredReclamations.isEmpty
                  ? const Center(child: Text("Aucune réclamation trouvée."))
                  : RefreshIndicator(
                      onRefresh: _refreshList,
                      child: ListView.builder(
                        itemCount: filteredReclamations.length,
                        itemBuilder: (context, index) {
                          final reclamation = filteredReclamations[index];
                          return GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => ReclamationDetailScreen(
                                    reclamation: reclamation,
                                    onEdit: handleEdit,
                                    onDelete: handleDelete,
                                  ),
                                ),
                              );
                              await _refreshList();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              child: ReclamationCard(reclamation: reclamation),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onAddPressed,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle réclamation'),
      ),
    );
  }
}
