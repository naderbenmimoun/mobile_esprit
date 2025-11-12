import 'package:flutter/material.dart';
import '../models/reclamation.dart';
import 'create_reclamation_screen.dart';

class ReclamationDetailScreen extends StatelessWidget {
  final Reclamation reclamation;
  final void Function(String id) onDelete;
  final void Function(Reclamation updatedReclamation) onEdit;

  const ReclamationDetailScreen({
    Key? key,
    required this.reclamation,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la réclamation'),
        content: const Text('Es-tu sûr de vouloir supprimer cette réclamation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete),
            onPressed: () {
              onDelete(reclamation.id);
              Navigator.of(ctx).pop(); // Ferme le dialog
              Navigator.of(context).pop(); // Retour à la liste
            },
            label: const Text('Supprimer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editReclamation(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => CreateReclamationScreen(
          initialTitre: reclamation.titre,
          initialDescription: reclamation.description,
        ),
      ),
    );
    if (result is Map<String, String>) {
      final updated = Reclamation(
        id: reclamation.id,
        titre: result['titre'] ?? reclamation.titre,
        description: result['description'] ?? reclamation.description,
        statut: reclamation.statut,
        dateCreation: reclamation.dateCreation,
      );
      onEdit(updated);
      Navigator.of(context).pop(); // Retour à la liste après édition
    }
  }

  String _formatFullDate(BuildContext context, DateTime date) {
    final loc = MaterialLocalizations.of(context);
    final dateStr = loc.formatFullDate(date);
    final timeStr = loc.formatTimeOfDay(
      TimeOfDay.fromDateTime(date),
      alwaysUse24HourFormat: true,
    );
    return '$dateStr • $timeStr';
  }

  // Couleur de base selon le statut
  Color _statusBaseColor(String statut, BuildContext context) {
    final s = statut.toLowerCase();
    if (s.contains('résolu') || s.contains('resolu') || s.contains('resolved')) {
      return Colors.green;
    }
    if (s.contains('en cours') || s.contains('pending') || s.contains('attente') || s.contains('progress')) {
      return Colors.amber;
    }
    if (s.contains('fermé') || s.contains('ferme') || s.contains('closed')) {
      return Colors.red;
    }
    return Theme.of(context).colorScheme.primary;
  }

  // Utilitaires pour teintes/contraste (compatibles Color "simples")
  Color _tint(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    final light = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(light).toColor();
  }

  Color _labelOn(Color bg) {
    // texte sombre si fond clair, sinon texte clair
    return bg.computeLuminance() > 0.6 ? const Color(0xFF111111) : Colors.white;
    // Ajusté pour rester lisible sur Chips
  }

  Widget _statusChip(BuildContext context) {
    final base = _statusBaseColor(reclamation.statut, context);
    final border = base.withOpacity(0.35);
    final bg = base.withOpacity(0.12);
    final avatarBg = base.withOpacity(0.25);
    final iconColor = _tint(base, -0.2);
    final labelColor = _tint(base, -0.35);

    return Chip(
      label: Text(
        reclamation.statut,
        style: TextStyle(
          color: labelColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: bg,
      side: BorderSide(color: border),
      avatar: CircleAvatar(
        backgroundColor: avatarBg,
        child: Icon(Icons.flag, color: iconColor, size: 16),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final titleInitial = reclamation.titre.isNotEmpty ? reclamation.titre[0].toUpperCase() : '?';

    final appBarStart = theme.appBarTheme.backgroundColor ?? cs.primary;
    final appBarEnd = cs.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail Réclamation'),
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [appBarStart, appBarEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit),
            onPressed: () => _editReclamation(context),
          ),
          IconButton(
            tooltip: 'Supprimer',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: cs.primary.withOpacity(0.15),
                        child: Text(
                          titleInitial,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reclamation.titre,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _statusChip(context),
                                _InfoPill(
                                  icon: Icons.calendar_today_rounded,
                                  label: _formatFullDate(context, reclamation.dateCreation),
                                ),
                                _InfoPill(
                                  icon: Icons.tag,
                                  label: 'Réf. ${reclamation.id}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Description
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description_outlined, color: cs.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Description',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        reclamation.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                          color: cs.onSurface.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Métadonnées
              Container(
                decoration: BoxDecoration(
                  color: cs.secondary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.15)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _MetaRow(
                      icon: Icons.info_outline,
                      label: 'Statut',
                      value: reclamation.statut,
                    ),
                    const SizedBox(height: 8),
                    _MetaRow(
                      icon: Icons.event,
                      label: 'Créée le',
                      value: _formatFullDate(context, reclamation.dateCreation),
                    ),
                    const SizedBox(height: 8),
                    _MetaRow(
                      icon: Icons.key,
                      label: 'Identifiant',
                      value: reclamation.id,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Barre d’actions en bas
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Modifier'),
                  onPressed: () => _editReclamation(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Supprimer'),
                  onPressed: () => _confirmDelete(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.secondary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onSurface.withOpacity(0.8)),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
