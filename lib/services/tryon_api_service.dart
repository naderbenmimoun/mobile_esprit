import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service pour interagir avec l'API TryOn.com.
class TryOnApiService {
  // Vos constantes API
  // J'ai mis à jour l'URL pour correspondre à l'endpoint de la requête initiale (POST)
  static const String _apiBaseUrl = 'https://tryon-api.com/api/v1/tryon';
  static const String _apiKey = 'ta_5d3660f708cd4bfdb0066f42d190a0f2';

  // --- MÉTHODE POUR INTERROGER LE STATUT (Polling) ---
  Future<Uint8List?> _pollForTryOnResult(String statusUrl) async {
    final statusUri = Uri.parse('https://tryon-api.com$statusUrl');

    // Durée d'attente maximale : 60 tentatives * 2 secondes = 120 secondes.
    const int maxAttempts = 60;
    const Duration pollingInterval = Duration(seconds: 2);

    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(pollingInterval);

      try {
        // Requête de statut (nécessite le header Authorization)
        final response = await http.get(
          statusUri,
          headers: {'Authorization': 'Bearer $_apiKey'},
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);

          if (data['status'] == 'COMPLETED' && data.containsKey('imageUrl')) {
            // 1. Déclarer et obtenir l'URL de l'image
            final imageUrl = data['imageUrl'] as String;

            // 2. 🔑 CRITIQUE : Préparer l'URI pour inclure la clé API comme paramètre de requête
            final baseUri = Uri.parse(imageUrl);
            // Nous utilisons un Map temporaire pour s'assurer que l'apiKey est présente
            final newQueryParameters = Map<String, dynamic>.from(baseUri.queryParameters);
            newQueryParameters['api_key'] = _apiKey;

            final imageUriWithKey = baseUri.replace(queryParameters: newQueryParameters.map((key, value) => MapEntry(key, value.toString())));

            print('✅ Job completed. Final Image URI: $imageUriWithKey');

            // ----------------------------------------------------
            // TENTATIVE DE TÉLÉCHARGEMENT DE L'IMAGE FINALE
            // ----------------------------------------------------
            final imageResponse = await http.get(
              imageUriWithKey,
              // 🔑 CRITIQUE : Maintenir le header Authorization si l'URL est sur un domaine sécurisé
              headers: {'Authorization': 'Bearer $_apiKey'},
            );

            print('🎯 Download Attempt Status: ${imageResponse.statusCode}');

            if (imageResponse.statusCode == 200) {
              // 🥳 SUCCÈS FINAL
              return imageResponse.bodyBytes;
            } else {
              // ❌ ÉCHEC DU TÉLÉCHARGEMENT
              print('❌ FATAL DOWNLOAD ERROR: Image retrieval failed with status ${imageResponse.statusCode}.');
              print('❌ Response Body (if available): ${imageResponse.body}');
              return null;
            }
          } else if (data['status'] == 'FAILED') {
            // ❌ L'API a rejeté l'image
            final reason = data.containsKey('reason') ? data['reason'] : 'No specific reason provided by API.';
            print('❌ TRYON JOB FAILED (API REJECTION): Reason: $reason');
            return null;
          }
        } else {
          print('Status API error during polling (Status: ${response.statusCode}). Body: ${response.body}');
          return null;
        }
      } on http.ClientException catch (e) {
        print('Polling Network Error: $e');
        return null;
      } catch (e) {
        print('Polling Unexpected Error: $e');
        return null;
      }
    }

    print('⚠️ Polling timed out after 120 seconds. Job might still be processing on server.');
    return null;
  }

  // --- MÉTHODE PRINCIPALE (Initial POST) ---
  Future<Uint8List?> generateTryOn({
    required File personImage,
    required File productImage,
  }) async {
    try {
      // Requête initiale
      var request = http.MultipartRequest('POST', Uri.parse(_apiBaseUrl));
      request.headers.addAll({
        'Authorization': 'Bearer $_apiKey',
        'Accept': 'application/json',
      });
      request.files.add(await http.MultipartFile.fromPath('person_images', personImage.path));
      request.files.add(await http.MultipartFile.fromPath('garment_images', productImage.path));
      request.fields['fast_mode'] = 'true';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 202) {
        // Tâche acceptée, démarrer l'interrogation du statut (polling)
        final Map<String, dynamic> data = json.decode(response.body);
        final statusUrl = data['statusUrl'] as String;
        print('🕒 TryOn job accepted. Polling status from: https://tryon-api.com$statusUrl');

        return await _pollForTryOnResult(statusUrl);
      } else if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('❌ TryOn API Initial Error (Status: ${response.statusCode}): ${response.body}');
        return null;
      }
    } on SocketException {
      print('❌ Network Error: Could not connect to the TryOn API.');
      return null;
    } catch (e) {
      print('❌ Unexpected error during TryOn API call: $e');
      return null;
    }
  }
}
