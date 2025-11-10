import 'package:flutter/material.dart';
import '../main.dart'; // AuthScope

import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';
import '../widgets/app_snackbar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _newPass = TextEditingController();
  final _imageUrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = AuthScope.read(context).currentUser!;
    _name.text = user.name;
    _email.text = user.email;
    _imageUrl.text = user.imageUrl ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _newPass.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      await AuthScope.read(context).updateProfile(
        name: _name.text,
        email: _email.text,
        newPassword: _newPass.text.isEmpty ? null : _newPass.text,
        imageUrl: _imageUrl.text.isEmpty ? null : _imageUrl.text,
      );
      if (!mounted) {
        return;
      }
      AppSnackBar.success(context, 'Profil mis à jour');
      setState(() => _newPass.clear());
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppSnackBar.error(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.watch(context).currentUser!;
    final scheme = Theme.of(context).colorScheme;

    ImageProvider? avatarImage;
    if ((user.imageUrl ?? '').isNotEmpty) {
      avatarImage = NetworkImage(user.imageUrl!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.2),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : '?',
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _name,
                          label: 'Nom',
                          icon: Icons.person_outline,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Nom requis'
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
                            final ok = RegExp(
                              r'^[^@]+@[^@]+\.[^@]+',
                            ).hasMatch(v);
                            return ok ? null : 'Email invalide';
                          },
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _imageUrl,
                          label: "URL de l'image (optionnel)",
                          icon: Icons.image_outlined,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _newPass,
                          label: 'Nouveau mot de passe (optionnel)',
                          icon: Icons.lock_reset,
                          obscure: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            return v.length < 6 ? '6 caractères minimum' : null;
                          },
                        ),
                        const SizedBox(height: 18),
                        AppButton(
                          label: 'Enregistrer',
                          loading: _saving,
                          onPressed: _saving ? null : _save,
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
