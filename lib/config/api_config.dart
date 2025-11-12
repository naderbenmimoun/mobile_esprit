class ApiConfig {
  // Récupère la clé depuis les arguments de lancement
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyCUKwBJoxsFuAObJTGXA_0QDm9958KrI7I',
  );

  // Vérifie si la clé est valide
  static bool get isApiKeyValid => geminiApiKey.isNotEmpty;
}
