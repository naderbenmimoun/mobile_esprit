import 'package:flutter/material.dart';
import '../routes/app_router.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';
import '../widgets/app_snackbar.dart';
import '../main.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = AuthScope.read(context);
    try {
      await auth.resetPassword(widget.email, _pass.text);
      if (!mounted) return;
      AppSnackBar.success(context, 'Mot de passe mis à jour');
      await AppRouter.pushFade(
        context,
        LoginPage(auth: auth),
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
    final auth = AuthScope.watch(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau mot de passe')),
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
                      controller: _pass,
                      label: 'Nouveau mot de passe',
                      icon: Icons.lock_outline,
                      obscure: true,
                      validator: (v) => (v == null || v.length < 6)
                          ? '6 caractères minimum'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _confirm,
                      label: 'Confirmer le mot de passe',
                      icon: Icons.lock_reset,
                      obscure: true,
                      validator: (v) => (v == null || v != _pass.text)
                          ? 'Les mots de passe ne correspondent pas'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    AppButton(
                      label: 'Mettre à jour',
                      loading: auth.isLoading,
                      onPressed: auth.isLoading ? null : _submit,
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
