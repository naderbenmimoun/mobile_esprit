import 'package:flutter/material.dart';
import '../main.dart'; // AuthScope
import '../routes/app_router.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';
import '../widgets/app_snackbar.dart';
import 'signup_page.dart';
import 'admin_dashboard.dart';
import 'client_home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
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
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final auth = AuthScope.read(context);
    try {
      await auth.login(email: _email.text, password: _pass.text);
      if (!mounted) {
        return;
      }
      final user = auth.currentUser!;
      AppSnackBar.success(context, 'Bienvenue ${user.name} !');
      final page = user.role == 'admin'
          ? AdminDashboard(auth: auth)
          : const ClientHome();
      await AppRouter.pushFade(context, page, replace: true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppSnackBar.error(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = AuthScope.watch(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
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
                          Container(
                            height: 86,
                            width: 86,
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: scheme.primary.withValues(alpha: 0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.verified_user,
                              color: scheme.onPrimaryContainer,
                              size: 44,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Gestion Utilisateurs',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Admin & Client',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _email,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
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
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _pass,
                          label: 'Mot de passe',
                          icon: Icons.lock_outline,
                          obscure: true,
                          validator: (v) {
                            return (v == null || v.length < 6)
                                ? '6 caractères minimum'
                                : null;
                          },
                        ),
                        const SizedBox(height: 18),
                        AppButton(
                          label: 'Se connecter',
                          loading: auth.isLoading,
                          onPressed: auth.isLoading ? null : _submit,
                          filled: true,
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            AppRouter.pushSlide(context, const SignupPage());
                          },
                          child: const Text("Créer un compte client"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
