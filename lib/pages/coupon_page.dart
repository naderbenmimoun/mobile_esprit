import 'package:flutter/material.dart';
import '../routes/app_router.dart';
import 'client_home.dart';

class CouponPage extends StatelessWidget {
  final String couponCode;
  const CouponPage({super.key, required this.couponCode});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Votre coupon de réduction')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Félicitations! Voici votre code coupon:',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SelectableText(
                      couponCode,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      AppRouter.pushSlide(context, const ClientHome(), replace: true);
                    },
                    child: const Text('Continuer vers l\'accueil'),
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
