import 'package:flutter/material.dart';

import '../models/user.dart';
import '../routes/app_router.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/app_card.dart';
import '../widgets/app_snackbar.dart';
import 'profile_page.dart';
import 'login_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, required this.auth});
  final AuthService auth;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _userService = UserService();
  late Future<List<AppUser>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _userService.allUsers();
  }

  Future<void> _refresh() async {
    setState(() {
      _usersFuture = _userService.allUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    final me = auth.currentUser!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord - Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profil',
            onPressed: () => AppRouter.pushSlide(context, const ProfilePage()),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () async {
              await auth.logout();
              if (!context.mounted) return;
              AppSnackBar.success(context, 'Déconnecté');
              if (!context.mounted) return;
              await AppRouter.pushFade(
                context,
                LoginPage(auth: auth),
                replace: true,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(child: Text(me.name[0].toUpperCase())),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour, ${me.name}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Rôle: ${me.role}',
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
              'Utilisateurs',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<AppUser>>(
              future: _usersFuture,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final users = snap.data!;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: users.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('Aucun utilisateur.')),
                        )
                      : Column(
                          children: users
                              .map(
                                (u) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: AppCard(
                                    onTap: () {},
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: u.role == 'admin'
                                              ? scheme.primaryContainer
                                              : scheme.secondaryContainer,
                                          child: Text(u.name[0].toUpperCase()),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                u.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                '${u.email} • ${u.role}',
                                                style: TextStyle(
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
