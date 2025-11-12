import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'package:intl/intl.dart';

class PaiementScreen extends StatefulWidget {
  const PaiementScreen({super.key});

  @override
  State<PaiementScreen> createState() => _PaiementScreenState();
}

class _PaiementScreenState extends State<PaiementScreen> {
  String paiement = 'carte';
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController cardController = TextEditingController();
  final TextEditingController expController = TextEditingController();
  final TextEditingController cvcController = TextEditingController();
  String? adresseJsonArg;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['adresse'] != null) {
      adresseJsonArg = args['adresse'] as String?;
    }
  }

  String _generateOrderNumber() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final random = now.millisecondsSinceEpoch % 1000;
    return 'CMD$dateStr$random';
  }

  String _getCurrentDateTime() {
    final now = DateTime.now().toUtc();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    }

  Future<void> _processPayment(CartProvider cart) async {
    if (paiement == 'carte' && !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      final orderId = await Provider.of<CartProvider>(context, listen: false).placeOrder(
        adresse: adresseJsonArg,
        modePaiement: paiement,
        numeroCommande: _generateOrderNumber(),
        date: _getCurrentDateTime(),
      );

      if (!mounted) return;

      _showSuccessDialog(orderId);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString());
    }
  }

  void _showSuccessDialog(int orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        icon: Icon(
          paiement == 'carte' ? Icons.celebration : Icons.money,
          color: paiement == 'carte' ? Colors.green : Colors.orange,
          size: 52,
        ),
        title: const Text(
          'Paiement réussi',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          paiement == 'carte'
              ? 'Merci pour votre paiement par carte !'
              : 'Votre commande est validée, paiement à la livraison.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(
                context,
                '/confirmationPaiement',
                arguments: {'orderId': orderId},
              );
            },
            child: Text(
              'OK',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur lors du paiement: $message'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = theme.colorScheme.background;
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 2,
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.payment, color: Colors.white, size: 32),
            const SizedBox(width: 10),
            Text(
              'Paiement',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressSteps(theme),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Étape finale : Paiement',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'Choisissez votre mode de paiement',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              _buildPaymentOptions(theme, primaryColor),
              const SizedBox(height: 28),
              _buildPaymentForm(primaryColor),
              const SizedBox(height: 8),
              const SizedBox(height: 18),
              _buildPaymentButton(cart),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSteps(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepCircle(theme, 1, done: true),
        _stepLine(theme),
        _stepCircle(theme, 2, done: true),
        _stepLine(theme),
        _stepCircle(theme, 3, done: true),
      ],
    );
  }

  Widget _buildPaymentOptions(ThemeData theme, Color primaryColor) {
    return Column(
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: paiement == 'carte' ? 7 : 2,
          shadowColor: paiement == 'carte' ? primaryColor.withOpacity(0.2) : null,
          child: RadioListTile<String>(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 12,
            ),
            value: 'carte',
            groupValue: paiement,
            onChanged: (value) => setState(() => paiement = value!),
            title: Text(
              'Carte bancaire',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            secondary: Icon(
              Icons.credit_card,
              color: primaryColor,
              size: 36,
            ),
            activeColor: primaryColor,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: paiement == 'cash' ? 7 : 2,
          shadowColor: paiement == 'cash' ? primaryColor.withOpacity(0.2) : null,
          child: RadioListTile<String>(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 12,
            ),
            value: 'cash',
            groupValue: paiement,
            onChanged: (value) => setState(() => paiement = value!),
            title: Text(
              'Espèces',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            secondary: const Icon(
              Icons.attach_money,
              color: Colors.green,
              size: 36,
            ),
            activeColor: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentForm(Color primaryColor) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: paiement == 'carte'
          ? Form(
              key: _formKey,
              child: Column(
                children: [
                  _StyledTextField(
                    controller: nameController,
                    label: 'Nom sur la carte',
                    icon: Icons.person,
                    color: primaryColor,
                    validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null,
                  ),
                  const SizedBox(height: 18),
                  _StyledTextField(
                    controller: cardController,
                    label: 'Numéro de carte',
                    icon: Icons.credit_card,
                    color: primaryColor,
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _StyledTextField(
                          controller: expController,
                          label: 'Expiration',
                          icon: Icons.date_range,
                          color: primaryColor,
                          keyboardType: TextInputType.datetime,
                          validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _StyledTextField(
                          controller: cvcController,
                          label: 'CVC',
                          icon: Icons.lock,
                          color: primaryColor,
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                ],
              ),
            )
          : const SizedBox(key: ValueKey(2), height: 72),
    );
  }

  Widget _buildOrderSummary(ThemeData theme, CartProvider cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Récapitulatif',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 26),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${cart.total.toStringAsFixed(2)} €',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentButton(CartProvider cart) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: cart.items.isEmpty ? null : () => _processPayment(cart),
        child: Text(
          paiement == 'carte' ? 'Payer par carte' : 'Payer en espèces',
        ),
      ),
    );
  }

  Widget _stepCircle(ThemeData theme, int number, {bool done = false}) =>
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: done ? theme.colorScheme.primary : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: theme.colorScheme.primary, width: 2),
        ),
        alignment: Alignment.center,
        child: done
            ? const Icon(Icons.check, color: Colors.white, size: 22)
            : Text(
                number.toString(),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      );

  Widget _stepLine(ThemeData theme) =>
      Container(width: 40, height: 2, color: theme.colorScheme.primary);

  @override
  void dispose() {
    nameController.dispose();
    cardController.dispose();
    expController.dispose();
    cvcController.dispose();
    super.dispose();
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;
  final TextInputType? keyboardType;
  final double fontSize;
  final double labelSize;
  final String? Function(String?)? validator;

  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.color,
    this.keyboardType,
    this.fontSize = 16,
    this.labelSize = 15,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      cursorColor: color,
      validator: validator,
      style: TextStyle(fontSize: fontSize, letterSpacing: 1),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: labelSize,
          fontWeight: FontWeight.w500,
          color: color,
        ),
        prefixIcon: Icon(icon, color: color, size: 26),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color.withOpacity(0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade300, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
      ),
    );
  }
}
