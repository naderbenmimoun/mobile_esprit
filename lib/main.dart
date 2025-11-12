import 'package:flutter/material.dart';

import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/admin_dashboard.dart';
import 'pages/client_home.dart';

// NOTE: Build failure originates from host path "C:\Users\NADER\ BM\...".
// Ensure no file named "C:\Users\NADER" blocks directory creation or move project to a path without spaces.

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

// Custom page transition (fade + gentle scale)
class _SmoothPageTransitions extends PageTransitionsBuilder {
  const _SmoothPageTransitions();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
        child: child,
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthService();
  await auth.init(); // Init DB + seed admin

  // Debug / instruction helper:
  // L'admin seedé est défini dans services/auth_service.dart.
  // Ouvrez ce fichier et cherchez une fonction init/seedAdmin pour
  // voir le login / mot de passe créés lors du seed.
  // Si vous voulez que j'insère des identifiants connus (ex: admin@example.com / Admin123!),
  // fournissez services/auth_service.dart et je l'adapterai.
  debugPrint(
    'DEBUG: Vérifiez c:\\Users\\NADER BM\\Desktop\\flutter_user\\lib\\services\\auth_service.dart pour les informations du compte admin.',
  );

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
    final darkScheme = ColorScheme.fromSeed(
      seedColor: color,
      brightness: Brightness.dark,
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
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _SmoothPageTransitions(),
            TargetPlatform.iOS: _SmoothPageTransitions(),
            TargetPlatform.windows: _SmoothPageTransitions(),
            TargetPlatform.linux: _SmoothPageTransitions(),
            TargetPlatform.macOS: _SmoothPageTransitions(),
          },
        ),
        snackBarTheme: snackBarTheme,
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        ),
        cardTheme: CardThemeData(
          elevation: 3,
          shadowColor: scheme.shadow.withValues(alpha: 0.18),
          surfaceTintColor: scheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surface.withValues(alpha: 0.55),
          // Glass-like border refinement
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: scheme.primary, width: 2),
          ),
          floatingLabelStyle: TextStyle(
            color: scheme.primary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2.8,
            shadowColor: scheme.primary.withValues(alpha: 0.35),
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _SmoothPageTransitions(),
            TargetPlatform.iOS: _SmoothPageTransitions(),
            TargetPlatform.windows: _SmoothPageTransitions(),
            TargetPlatform.linux: _SmoothPageTransitions(),
            TargetPlatform.macOS: _SmoothPageTransitions(),
          },
        ),
      ),
      themeMode: ThemeMode.system,
      home: Builder(
        builder: (context) {
          final auth = AuthScope.watch(context);
          if (auth.currentUser == null) {
            return LoginPage(auth: auth); // <-- pass auth instance to LoginPage
          }
          return auth.currentUser!.role == 'admin'
              ? AdminDashboard(auth: auth)
              : const ClientHome();
        },
      ),
    );
  }
}
