import 'package:flutter/material.dart';
import '../main.dart'; // AuthScope

import '../routes/app_router.dart';
import '../widgets/app_card.dart';
import '../widgets/app_snackbar.dart';
import 'profile_page.dart';
import 'login_page.dart';

class ClientHome extends StatelessWidget {
  const ClientHome({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.watch(context);
    final user = auth.currentUser!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil - Client'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => AppRouter.pushSlide(context, const ProfilePage()),
          ),
          IconButton(
            tooltip: 'Mes réclamations',
            icon: const Icon(Icons.report_gmailerrorred_outlined),
            onPressed: () => Navigator.pushNamed(context, '/reclamations'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (!context.mounted) {
                return;
              }
              AppSnackBar.success(context, 'Déconnecté');
              if (!context.mounted) {
                return;
              }
              await AppRouter.pushFade(
                context,
                LoginPage(auth: auth),
                replace: true,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.secondaryContainer,
                    child: Text(user.name[0].toUpperCase()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenue, ${user.name}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          user.email,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Actions rapides',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            AppCard(
              onTap: () => AppRouter.pushScale(context, const ProfilePage()),
              child: Row(
                children: const [
                  Icon(Icons.manage_accounts_outlined),
                  SizedBox(width: 12),
                  Expanded(child: Text('Gérer mon profil')),
                  Icon(Icons.chevron_right),
                ],
              ),
            ),
            const SizedBox(height: 8),
            AppCard(
              onTap: () => Navigator.pushNamed(context, '/reclamations'),
              child: Row(
                children: const [
                  Icon(Icons.report_gmailerrorred_outlined),
                  SizedBox(width: 12),
                  Expanded(child: Text('Mes réclamations')),
                  Icon(Icons.chevron_right),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
