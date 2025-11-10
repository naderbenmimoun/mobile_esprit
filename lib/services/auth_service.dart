import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../models/user.dart';
import 'db_service.dart';

class AuthService extends ChangeNotifier {
  final _db = DBService.instance;

  AppUser? currentUser;
  bool isLoading = false;

  Future<void> init() async {
    await _db.database; // ensure initialized + seed admin
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
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      final existing = await _db.getUserByEmail(email);
      if (existing != null) {
        throw Exception('Email déjà utilisé.');
      }
      final user = AppUser(
        name: name,
        email: email,
        passwordHash: hashPassword(password),
        role: 'client',
        imageUrl: null,
      );
      final id = await _db.insertUser(user);
      currentUser = user.copyWith(id: id);
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
      notifyListeners();
      return user;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    currentUser = null;
    notifyListeners();
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
}
