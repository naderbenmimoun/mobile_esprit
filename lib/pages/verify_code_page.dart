import 'package:flutter/material.dart';
import '../routes/app_router.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';
import '../widgets/app_snackbar.dart';
import '../main.dart';
import 'reset_password_page.dart';

class VerifyCodePage extends StatefulWidget {
  final String email;
  const VerifyCodePage({super.key, required this.email});

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  final _code = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = AuthScope.read(context);
    try {
      await auth.verifyResetCode(widget.email, _code.text.trim());
      if (!mounted) return;
      AppSnackBar.success(context, 'Code vérifié');
      await AppRouter.pushSlide(
        context,
        ResetPasswordPage(email: widget.email),
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Vérifier le code')),
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
                    Text(
                      'Un code a été envoyé à ${widget.email}',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _code,
                      label: 'Code à 6 chiffres',
                      icon: Icons.verified_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Code requis';
                        }
                        if (v.trim().length != 6) {
                          return 'Le code doit contenir 6 chiffres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    AppButton(
                      label: 'Continuer',
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
