import 'package:flutter/material.dart';

class UserProfileCard extends StatelessWidget {
  final String morphology;
  final String gender;
  final String season;

  const UserProfileCard({
    super.key,
    required this.morphology,
    required this.gender,
    required this.season,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.secondaryContainer,
            child: const Icon(Icons.person_outline),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gender: $gender'),
                Text('Morphology: $morphology'),
                Text('Season: $season'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
