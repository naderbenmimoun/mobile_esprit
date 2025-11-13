import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../models/user.dart';
import 'db_service.dart';
import 'session_service.dart';

class AuthService extends ChangeNotifier {
  final _db = DBService.instance;

  AppUser? currentUser;
  bool isLoading = false;
  final Map<String, (_ResetCode code, DateTime expiresAt)> _resetCodes = {};

  Future<void> init() async {
    await _db.database; // ensure initialized + seed admin
    _seedAdmin();
  }

  void _seedAdmin() {
    // ignore: unused_local_variable
    final record = _store[adminEmail];
    if (record == null) {
      _store[adminEmail] = {
        'password': adminPassword,
        'role': 'admin',
        'id': '1',
      };
      debugPrint('DEBUG: Admin seedé -> $adminEmail / $adminPassword');
    }
  }

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<AppUser> signup({
    required String name,
    required String email,
    required String password,
    required String gender,
    required String morphology,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      final existing = await _db.getUserByEmail(email);
      if (existing != null) {
        throw Exception('Email déjà utilisé.');
      }
      final coupon = _generateCoupon();
      final user = AppUser(
        name: name,
        email: email,
        passwordHash: hashPassword(password),
        role: 'client',
        imageUrl: null,
        gender: gender,
        morphology: morphology,
        couponCode: coupon,
      );
      final id = await _db.insertUser(user);
      currentUser = user.copyWith(id: id);
      // Persist session userId
      await SessionService.instance.setUserId(currentUser!.id!);
      notifyListeners();
      return currentUser!;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      final user = await _db.getUserByEmail(email);
      await Future.delayed(
        const Duration(milliseconds: 400),
      ); // petite attente pour animation
      if (user == null) {
        throw Exception('Utilisateur introuvable.');
      }
      final hash = hashPassword(password);
      if (hash != user.passwordHash) {
        throw Exception('Mot de passe invalide.');
      }
      currentUser = user;
      // Persist session userId
      await SessionService.instance.setUserId(currentUser!.id!);
      notifyListeners();
      return user;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    currentUser = null;
    // Clear session on logout
    await SessionService.instance.clear();
    notifyListeners();
  }

  Future<void> requestPasswordReset(String email) async {
    isLoading = true;
    notifyListeners();
    try {
      final user = await _db.getUserByEmail(email);
      await Future.delayed(const Duration(milliseconds: 300));
      if (user == null) {
        throw Exception("Utilisateur introuvable.");
      }
      final code = _ResetCode.generate();
      final expires = DateTime.now().add(const Duration(minutes: 10));
      _resetCodes[user.email.toLowerCase()] = (code, expires);
      debugPrint('DEBUG: Code de réinitialisation pour ${user.email}: ${code.value} (expire à $expires)');
      // Ici vous pourriez envoyer le code par email via un service externe.
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyResetCode(String email, String code) async {
    final key = email.trim().toLowerCase();
    final entry = _resetCodes[key];
    if (entry == null) {
      throw Exception('Aucune demande en cours.');
    }
    final (stored, expiresAt) = entry;
    if (DateTime.now().isAfter(expiresAt)) {
      _resetCodes.remove(key);
      throw Exception('Code expiré.');
    }
    if (stored.value != code.trim()) {
      throw Exception('Code invalide.');
    }
  }

  Future<void> resetPassword(String email, String newPassword) async {
    isLoading = true;
    notifyListeners();
    try {
      final key = email.trim().toLowerCase();
      final user = await _db.getUserByEmail(key);
      if (user == null) {
        throw Exception('Utilisateur introuvable.');
      }
      // Optionally ensure a verified code exists before reset
      if (!_resetCodes.containsKey(key)) {
        throw Exception('Veuillez d\'abord vérifier le code.');
      }
      final updated = user.copyWith(
        passwordHash: hashPassword(newPassword),
      );
      await _db.updateUser(updated);
      _resetCodes.remove(key);
      if (currentUser?.id == updated.id) {
        currentUser = updated;
        notifyListeners();
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<AppUser> updateProfile({
    String? name,
    String? email,
    String? newPassword,
    String? imageUrl,
  }) async {
    if (currentUser == null) throw Exception('Aucun utilisateur connecté.');
    final me = currentUser!;
    final maybeOther = email != null ? await _db.getUserByEmail(email) : null;
    if (maybeOther != null && maybeOther.id != me.id) {
      throw Exception('Cet email est déjà utilisé.');
    }
    final updated = me.copyWith(
      name: name ?? me.name,
      email: email ?? me.email,
      passwordHash: newPassword != null && newPassword.isNotEmpty
          ? hashPassword(newPassword)
          : me.passwordHash,
      imageUrl: imageUrl ?? me.imageUrl,
    );
    await _db.updateUser(updated);
    currentUser = updated;
    notifyListeners();
    return updated;
  }

  // Simple "in-memory" store: email -> {password, role, id}
  final Map<String, Map<String, String>> _store = {};

  // Test admin credentials (modifiable)
  static const String adminEmail = 'admin@example.com';
  static const String adminPassword = 'Admin123!';

  String _generateCoupon() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final now = DateTime.now().millisecondsSinceEpoch;
    var x = now;
    final buf = StringBuffer('CP-');
    for (int i = 0; i < 8; i++) {
      x = (x * 1103515245 + 12345) & 0x7fffffff;
      buf.write(alphabet[x % alphabet.length]);
    }
    return buf.toString();
  }
}

class _ResetCode {
  final String value;
  const _ResetCode(this.value);
  static _ResetCode generate() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final six = (now % 1000000).toString().padLeft(6, '0');
    return _ResetCode(six);
  }
}
