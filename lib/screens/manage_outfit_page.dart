// lib/screens/manage_outfit_page.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/outfit.dart';
import '../database/database_helper.dart';


class ManageOutfitPage extends StatefulWidget {
  final Outfit? editOutfit;
  const ManageOutfitPage({super.key, this.editOutfit});

  @override
  State<ManageOutfitPage> createState() => _ManageOutfitPageState();
}

class _ManageOutfitPageState extends State<ManageOutfitPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _matchCtrl = TextEditingController();
  final _morphologiesCtrl = TextEditingController();
  final _seasonsCtrl = TextEditingController();
  String _gender = 'Unisex';

  final db = DatabaseHelper.instance;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.editOutfit != null) {
      final e = widget.editOutfit!;
      _nameCtrl.text = e.name;
      _imageCtrl.text = e.imagePath;
      _priceCtrl.text = e.price.toString();
      _matchCtrl.text = e.matchScore.toString();
      _morphologiesCtrl.text = e.morphologies.join(',');
      _seasonsCtrl.text = e.seasons.join(',');
      _gender = e.gender;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _imageCtrl.dispose();
    _priceCtrl.dispose();
    _matchCtrl.dispose();
    _morphologiesCtrl.dispose();
    _seasonsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final id = widget.editOutfit?.id ?? const Uuid().v4();

    final outfit = Outfit(
      id: id,
      name: _nameCtrl.text.trim(),
      imagePath: _imageCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
      gender: _gender,
      morphologies: _morphologiesCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      seasons: _seasonsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      matchScore: double.tryParse(_matchCtrl.text.trim()) ?? 0.0,
    );

    if (widget.editOutfit != null) {
      await db.updateOutfit(outfit);
    } else {
      await db.insertOutfit(outfit);
    }

    setState(() => _saving = false);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (widget.editOutfit == null) return;
    final id = widget.editOutfit!.id;
    await db.deleteOutfit(id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editOutfit != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Outfit' : 'Add Outfit')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _imageCtrl,
                    decoration: const InputDecoration(labelText: 'Image path or URL'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter image path' : null,
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _matchCtrl,
                        decoration: const InputDecoration(labelText: 'Match Score (%)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: const [
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Unisex', child: Text('Unisex')),
                    ],
                    onChanged: (v) => setState(() => _gender = v ?? _gender),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _morphologiesCtrl,
                    decoration: const InputDecoration(labelText: 'Morphologies (comma separated)'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _seasonsCtrl,
                    decoration: const InputDecoration(labelText: 'Seasons (comma separated)'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving...' : (isEdit ? 'Save Changes' : 'Add Outfit')),
                  ),
                  if (isEdit)
                    TextButton(
                      onPressed: _delete,
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete Outfit'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
