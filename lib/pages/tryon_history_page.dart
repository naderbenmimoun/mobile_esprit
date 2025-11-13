import 'dart:io';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/tryon_history.dart';

class TryOnHistoryPage extends StatefulWidget {
  const TryOnHistoryPage({super.key});

  @override
  State<TryOnHistoryPage> createState() => _TryOnHistoryPageState();
}

class _TryOnHistoryPageState extends State<TryOnHistoryPage> {
  final db = DatabaseHelper.instance;
  List<TryOnHistory> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await db.getTryOnHistory();
    setState(() => history = list);
  }

  Future<void> _deleteTryOn(int id) async {
    await db.deleteTryOnHistory(id);
    await _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Try-On History')),
      body: history.isEmpty
          ? const Center(child: Text('No try-on history yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, i) {
                final item = history[i];
                return Card(
                  child: ListTile(
                    leading: item.generatedImagePath != null
                        ? Image.file(
                            File(item.generatedImagePath!),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image_not_supported),
                    title: Text('Outfit ID: ${item.outfitId}'),
                    subtitle: Text(item.triedAt.toLocal().toString()),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteTryOn(item.id!),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
