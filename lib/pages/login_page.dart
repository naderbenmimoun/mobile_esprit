import 'package:flutter/material.dart';
import 'dart:ui'; // For BackdropFilter blur
import '../main.dart'; // AuthScope
import '../routes/app_router.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';
import '../widgets/app_snackbar.dart';
import 'signup_page.dart';
import 'admin_dashboard.dart';
import 'client_home.dart';
import '../services/auth_service.dart';

// NOTE: Login UI unchanged; build error is unrelated (filesystem path issue on host).
// Move project or fix user directory before expecting successful build.

class LoginPage extends StatefulWidget {
  final AuthService auth;
  const LoginPage({Key? key, required this.auth}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;
  bool _showPass = false; // toggle visibility
  late Animation<Offset> _formSlide;
  late Animation<double> _formFade;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _formFade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _pass.text;
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remplissez tous les champs')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.auth.login(email: email, password: pass);
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Connexion réussie')));
      // AuthScope notifie et main.dart redirigera automatiquement selon le rôle.
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _fillAdmin() {
    _email.text = AuthService.adminEmail;
    _pass.text = AuthService.adminPassword;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primaryContainer.withValues(alpha: 0.65),
                  scheme.secondaryContainer.withValues(alpha: 0.55),
                  scheme.surfaceContainerHighest.withValues(
                    alpha: 0.6,
                  ), // replaced surfaceVariant
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Subtle radial highlight
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 1.2,
                    colors: [
                      scheme.primary.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                    center: const Alignment(-0.4, -0.6),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _scale,
                        child: FadeTransition(
                          opacity: _fade,
                          child: Column(
                            children: [
                              Hero(
                                tag: 'app_logo_hero',
                                child: Container(
                                  height: 92,
                                  width: 92,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        scheme.primary,
                                        scheme.primaryContainer,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: scheme.primary.withValues(
                                          alpha: 0.28,
                                        ),
                                        blurRadius: 28,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.verified_user,
                                    color: scheme.onPrimary,
                                    size: 46,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Gestion Utilisateurs',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                'Admin & Client',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SlideTransition(
                        position: _formSlide,
                        child: FadeTransition(
                          opacity: _formFade,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 26,
                                  vertical: 30,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.surface.withValues(alpha: 0.55),
                                  border: Border.all(
                                    color: scheme.outlineVariant.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: scheme.shadow.withValues(
                                        alpha: 0.12,
                                      ),
                                      blurRadius: 36,
                                      offset: const Offset(0, 16),
                                    ),
                                  ],
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      AppTextField(
                                        controller: _email,
                                        label: 'Email',
                                        icon: Icons.email_outlined,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) {
                                            return 'Email requis';
                                          }
                                          final ok = RegExp(
                                            r'^[^@]+@[^@]+\.[^@]+',
                                          ).hasMatch(v);
                                          return ok ? null : 'Email invalide';
                                        },
                                      ),
                                      const SizedBox(height: 18),
                                      AppTextField(
                                        controller: _pass,
                                        label: 'Mot de passe',
                                        icon: Icons.lock_outline,
                                        obscure: !_showPass,
                                        validator: (v) {
                                          return (v == null || v.length < 6)
                                              ? '6 caractères minimum'
                                              : null;
                                        },
                                      ),
                                      // Toggle show/hide password
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: () => setState(
                                            () => _showPass = !_showPass,
                                          ),
                                          icon: Icon(
                                            _showPass
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            size: 18,
                                            color: scheme.primary,
                                          ),
                                          label: Text(
                                            _showPass ? 'Masquer' : 'Afficher',
                                            style: TextStyle(
                                              color: scheme.primary,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeOut,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              scheme.primary,
                                              scheme.primaryContainer,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: scheme.primary.withValues(
                                                alpha: 0.35,
                                              ),
                                              blurRadius: 22,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: AppButton(
                                          label: 'Se connecter',
                                          loading: _loading,
                                          onPressed: _loading ? null : _submit,
                                          filled: true,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      TextButton(
                                        onPressed: () {
                                          AppRouter.pushSlide(
                                            context,
                                            const SignupPage(),
                                          );
                                        },
                                        child: Text(
                                          "Créer un compte client",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: scheme.primary,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      FilledButton.tonal(
                                        onPressed: _fillAdmin,
                                        child: const Text(
                                          'Utiliser compte admin (test)',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Si vous voyez "Utilisateur introuvable", utilisez le bouton admin ou créez un compte client.',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
