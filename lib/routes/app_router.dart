import 'package:flutter/material.dart';

class AppRouter {
  static Future<T?> pushFade<T>(
    BuildContext context,
    Widget page, {
    bool replace = false,
  }) {
    final route = PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );
    return replace
        ? Navigator.pushReplacement(context, route)
        : Navigator.push(context, route);
  }

  static Future<T?> pushSlide<T>(
    BuildContext context,
    Widget page, {
    AxisDirection direction = AxisDirection.right,
    bool replace = false,
  }) {
    final beginOffset = switch (direction) {
      AxisDirection.up => const Offset(0, 0.2),
      AxisDirection.down => const Offset(0, -0.2),
      AxisDirection.left => const Offset(0.2, 0),
      AxisDirection.right => const Offset(-0.2, 0),
    };
    final route = PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final offset = Tween(begin: beginOffset, end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return SlideTransition(
          position: offset,
          child: FadeTransition(opacity: fade, child: child),
        );
      },
    );
    return replace
        ? Navigator.pushReplacement(context, route)
        : Navigator.push(context, route);
  }

  static Future<T?> pushScale<T>(
    BuildContext context,
    Widget page, {
    bool replace = false,
  }) {
    final route = PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: child,
      ),
    );
    return replace
        ? Navigator.pushReplacement(context, route)
        : Navigator.push(context, route);
  }
}
