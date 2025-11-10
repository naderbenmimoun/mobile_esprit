import 'package:flutter/material.dart';

class AppSnackBar {
  static void success(BuildContext context, String message) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: scheme.primary,
        content: Text(message, style: TextStyle(color: scheme.onPrimary)),
      ),
    );
  }

  static void error(BuildContext context, String message) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: scheme.error,
        content: Text(message, style: TextStyle(color: scheme.onError)),
      ),
    );
  }
}
