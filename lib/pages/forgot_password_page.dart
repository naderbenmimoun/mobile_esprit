import 'package:flutter/material.dart';
import '../routes/app_router.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';
import '../widgets/app_snackbar.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'verify_code_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = AuthScope.read(context);
    try {
      await auth.requestPasswordReset(_email.text.trim());
      if (!mounted) return;
      AppSnackBar.success(context, 'Code envoyé à votre email');
      await AppRouter.pushSlide(
        context,
        VerifyCodePage(email: _email.text.trim()),
        replace: true,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = AuthScope.watch(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
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
                        final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v);
                        return ok ? null : 'Email invalide';
                      },
                    ),
                    const SizedBox(height: 18),
                    AppButton(
                      label: 'Envoyer le code',
                      loading: auth.isLoading,
                      onPressed: auth.isLoading ? null : _submit,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Vous recevrez un code à 6 chiffres si l'email existe",
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
