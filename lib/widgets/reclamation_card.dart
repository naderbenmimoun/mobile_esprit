import 'package:flutter/material.dart';
import '../models/reclamation.dart';

class ReclamationCard extends StatelessWidget {
  final Reclamation reclamation;

  const ReclamationCard({Key? key, required this.reclamation}) : super(key: key);

  Color getStatutColor(String statut) {
    switch (statut) {
      case 'Ouvert':
        return Colors.orange;
      case 'En cours':
        return Colors.blue;
      case 'Résolu':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.report_problem, color: Theme.of(context).colorScheme.primary, size: 32),
        title: Text(reclamation.titre, style: Theme.of(context).textTheme.headlineMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reclamation.description),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text("Statut : ", style: TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: getStatutColor(reclamation.statut).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reclamation.statut,
                    style: TextStyle(
                      color: getStatutColor(reclamation.statut),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Text(
          "${reclamation.dateCreation.day}/${reclamation.dateCreation.month}/${reclamation.dateCreation.year}",
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
