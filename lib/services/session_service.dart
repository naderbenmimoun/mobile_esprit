import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  static const _keyUserId = 'current_user_id';

  Future<void> setUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  Future<int> getUserIdOrThrow() async {
    final id = await getUserId();
    if (id == null) {
      throw StateError('No active session: userId is not set');
    }
    return id;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
  }
}
