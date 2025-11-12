import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import '../services/storage_service.dart';

class ReclamationForm extends StatefulWidget {
  final void Function(String titre, String description, List<String> attachments) onSubmit;
  final String? initialTitre;
  final String? initialDescription;
  final List<String>? initialAttachments;

  const ReclamationForm({
    Key? key,
    required this.onSubmit,
    this.initialTitre,
    this.initialDescription,
    this.initialAttachments,
  }) : super(key: key);

  @override
  State<ReclamationForm> createState() => _ReclamationFormState();
}

class _ReclamationFormState extends State<ReclamationForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titreController;
  late final TextEditingController _descriptionController;
  final StorageService _storage = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  List<String> _attachments = [];
  bool _isProcessingAttachment = false;

  static const int maxAttachments = 5;
  static const int maxFileBytes = 5 * 1024 * 1024; // 5 MB
  static const allowedExt = ['.jpg', '.jpeg', '.png', '.pdf'];

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController(text: widget.initialTitre ?? '');
    _descriptionController = TextEditingController(text: widget.initialDescription ?? '');
    _attachments = widget.initialAttachments != null ? List.from(widget.initialAttachments!) : [];
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    if (_attachments.length >= maxAttachments) {
      _showSnack('Nombre maximum de pièces jointes atteint ($maxAttachments).');
      return;
    }
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      await _processPickedFile(File(picked.path));
    } catch (e) {
      _showSnack('Erreur lors de la sélection d\'image.');
    }
  }

  Future<void> _pickFromCamera() async {
    if (_attachments.length >= maxAttachments) {
      _showSnack('Nombre maximum de pièces jointes atteint ($maxAttachments).');
      return;
    }
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.camera);
      if (picked == null) return;
      await _processPickedFile(File(picked.path));
    } catch (e) {
      _showSnack('Erreur lors de la prise de photo.');
    }
  }

  Future<void> _pickFiles() async {
    if (_attachments.length >= maxAttachments) {
      _showSnack('Nombre maximum de pièces jointes atteint ($maxAttachments).');
      return;
    }
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    if (res == null) return;
    final files = res.paths.whereType<String>().map((p) => File(p)).toList();
    for (final f in files) {
      if (_attachments.length >= maxAttachments) {
        _showSnack('Nombre maximum de pièces jointes atteint ($maxAttachments).');
        break;
      }
      await _processPickedFile(f);
    }
  }

  Future<void> _processPickedFile(File file) async {
    setState(() => _isProcessingAttachment = true);
    try {
      final bytes = await file.length();
      if (bytes > maxFileBytes) {
        _showSnack('Fichier trop volumineux (max 5MB).');
        return;
      }
      final ext = file.path.toLowerCase();
      if (!allowedExt.any((e) => ext.endsWith(e))) {
        _showSnack('Type de fichier non autorisé.');
        return;
      }

      // copy to app folder
      final savedUri = await _storage.saveFileLocally(file);
      setState(() {
        _attachments.add(savedUri);
      });
    } catch (e) {
      _showSnack('Erreur lors du traitement du fichier.');
    } finally {
      setState(() => _isProcessingAttachment = false);
    }
  }

  void _removeAttachmentAt(int index) {
    final uri = _attachments[index];
    setState(() {
      _attachments.removeAt(index);
    });
    // try delete file async (best-effort)
    _storage.deleteLocalFile(uri);
  }

  void _openAttachment(String uriString) {
    final uri = Uri.parse(uriString);
    if (uri.scheme == 'file') {
      OpenFile.open(uri.toFilePath());
    } else {
      OpenFile.open(uriString);
    }
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _handleSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final titre = _titreController.text.trim();
    final description = _descriptionController.text.trim();
    widget.onSubmit(titre, description, List.from(_attachments));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _titreController,
            decoration: const InputDecoration(
              labelText: 'Titre',
              prefixIcon: Icon(Icons.title),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Veuillez entrer un titre';
              if (value.trim().length < 3) return 'Titre trop court (min 3 caractères)';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              prefixIcon: Icon(Icons.description),
              border: OutlineInputBorder(),
            ),
            maxLines: 6,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Veuillez entrer une description';
              if (value.trim().length < 10) return 'Description trop courte (min 10 caractères)';
              return null;
            },
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.photo),
                label: const Text('Galerie'),
                onPressed: _isProcessingAttachment ? null : _pickFromGallery,
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Caméra'),
                onPressed: _isProcessingAttachment ? null : _pickFromCamera,
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Fichiers'),
                onPressed: _isProcessingAttachment ? null : _pickFiles,
              ),
              const SizedBox(width: 8),
              if (_isProcessingAttachment) const CircularProgressIndicator(),
            ],
          ),
          const SizedBox(height: 12),

          if (_attachments.isNotEmpty)
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _attachments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final uri = Uri.parse(_attachments[idx]);
                  final path = uri.toFilePath();
                  final isPdf = path.toLowerCase().endsWith('.pdf');
                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _openAttachment(_attachments[idx]),
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).dividerColor),
                            color: Colors.grey.shade100,
                          ),
                          child: isPdf
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.picture_as_pdf, size: 36, color: Colors.red),
                                      SizedBox(height: 4),
                                      Text('PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(path),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeAttachmentAt(idx),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              minimumSize: const Size(double.infinity, 48),
            ),
            icon: const Icon(Icons.send),
            label: const Text('Envoyer', style: TextStyle(fontSize: 16)),
            onPressed: _handleSubmit,
          ),
        ],
      ),
    );
  }
}
