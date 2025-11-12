import 'package:flutter/material.dart';
import '../widgets/reclamation_form.dart';

class CreateReclamationScreen extends StatelessWidget {
  final String? initialTitre;
  final String? initialDescription;
  final List<String>? initialAttachments;

  const CreateReclamationScreen({
    Key? key,
    this.initialTitre,
    this.initialDescription,
    this.initialAttachments,
  }) : super(key: key);

  void _onSubmit(BuildContext context, String titre, String description, List<String> attachments) {
    Navigator.pop(context, {
      'titre': titre,
      'description': description,
      'attachments': attachments,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(initialTitre == null ? "Nouvelle Réclamation" : "Modifier Réclamation"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ReclamationForm(
          onSubmit: (titre, description, attachments) =>
              _onSubmit(context, titre, description, attachments),
          initialTitre: initialTitre,
          initialDescription: initialDescription,
          initialAttachments: initialAttachments,
        ),
      ),
    );
  }
}
