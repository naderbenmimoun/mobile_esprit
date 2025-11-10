import 'package:flutter/material.dart';

import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/admin_dashboard.dart';
import 'pages/client_home.dart';

// InheritedNotifier simple pour remplacer provider
class AuthScope extends InheritedNotifier<AuthService> {
  const AuthScope({super.key, required super.notifier, required super.child});

  static AuthService watch(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()!.notifier!;

  static AuthService read(BuildContext context) =>
      (context.getElementForInheritedWidgetOfExactType<AuthScope>()!.widget
              as AuthScope)
          .notifier!;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthService();
  await auth.init(); // Init DB + seed admin
  runApp(AuthScope(notifier: auth, child: const GestionUserApp()));
}

class GestionUserApp extends StatelessWidget {
  const GestionUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF6750A4); // Seed color
    final scheme = ColorScheme.fromSeed(
      seedColor: color,
      brightness: Brightness.light,
    );
    final snackBarTheme = SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentTextStyle: const TextStyle(fontWeight: FontWeight.w600),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestion Users',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        snackBarTheme: snackBarTheme,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surfaceContainerHighest,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: scheme.primary, width: 2),
          ),
          labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 1.5,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
      home: Builder(
        builder: (context) {
          final auth = AuthScope.watch(context);
          if (auth.currentUser == null) {
            return const LoginPage();
          }
          return auth.currentUser!.role == 'admin'
              ? AdminDashboard(auth: auth)
              : const ClientHome();
        },
      ),
    );
  }
}
