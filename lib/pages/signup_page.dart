import 'package:flutter/material.dart';
import '../main.dart'; // AuthScope
import '../routes/app_router.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';
import '../widgets/app_snackbar.dart';
import 'client_home.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _gender = 'Unisex';
  String _morphology = 'Oval';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final auth = AuthScope.read(context);
    try {
      await auth.signup(
        name: _name.text,
        email: _email.text,
        password: _pass.text,
        gender: _gender,
        morphology: _morphology,
      );
      if (!mounted) {
        return;
      }
      AppSnackBar.success(context, 'Compte créé avec succès');
      await AppRouter.pushSlide(context, const ClientHome(), replace: true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppSnackBar.error(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.watch(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte client')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: 1.0,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _name,
                        label: 'Nom complet',
                        icon: Icons.person_outline,
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'Nom trop court'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Genre',
                          prefixIcon: Icon(Icons.wc_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(value: 'Female', child: Text('Female')),
                          DropdownMenuItem(value: 'Unisex', child: Text('Unisex')),
                        ],
                        onChanged: (v) => setState(() => _gender = v ?? 'Unisex'),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Genre requis'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _morphology,
                        decoration: const InputDecoration(
                          labelText: 'Morphologie',
                          prefixIcon: Icon(Icons.analytics_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Oval', child: Text('Oval')),
                          DropdownMenuItem(value: 'Rectangle', child: Text('Rectangle')),
                          DropdownMenuItem(value: 'Triangle', child: Text('Triangle')),
                          DropdownMenuItem(value: 'Hourglass', child: Text('Hourglass')),
                          DropdownMenuItem(value: 'Pear', child: Text('Pear')),
                        ],
                        onChanged: (v) => setState(() => _morphology = v ?? 'Oval'),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Morphologie requise'
                            : null,
                      ),
                      const SizedBox(height: 14),
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
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _pass,
                        label: 'Mot de passe',
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
                        label: 'Créer mon compte',
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
      ),
    );
  }
}
