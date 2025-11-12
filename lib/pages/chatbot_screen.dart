import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  _ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.isError = false,
  }) : timestamp = timestamp ?? DateTime.now();

  _ChatMessage copyWith({String? text, bool? isError}) => _ChatMessage(
        text: text ?? this.text,
        isUser: isUser,
        timestamp: timestamp,
        isError: isError ?? this.isError,
      );
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  GenerativeModel? _model;
  ChatSession? _chat;
  String? _apiKey;

  static const String assistantContext = '''
Tu es l'assistant officiel du marketplace SmartFIT. 


INFORMATIONS SUR SMARTFIT :
- Marketplace de produits fitness et bien-être
- Livraison en 24-48h dans toute la France
- Service client disponible de 9h à 18h
- Retours gratuits sous 30 jours
- Plus de 5000 produits disponibles


RÔLE :
- Aide les clients avec leurs questions sur les produits, commandes, livraisons et réclamations
- Réponds en français de manière claire, concise et professionnelle
- Sois empathique et orienté solution


FONCTIONNALITÉS DE L'APP :
- Créer une réclamation (bouton + sur l'écran principal)
- Voir la liste des réclamations (statut : Ouvert, En cours, Résolu)
- Modifier une réclamation existante
- Suivre l'évolution du traitement


POLITIQUE DE RETOUR :
- Retours acceptés sous 30 jours
- Produits non ouverts et dans leur emballage d'origine
- Remboursement sous 5-7 jours ouvrés


DÉLAIS DE LIVRAISON :
- Standard : 3-5 jours ouvrés (gratuit dès 50€)
- Express : 24-48h (9,90€)
- Point relais : 2-4 jours ouvrés (4,90€)


CONTACT :
- Email : support@smartfit.fr
- Téléphone : 01 23 45 67 89 (Lun-Ven 9h-18h)
- Chat en direct dans l'application


LIMITES :
- Ne fournis JAMAIS d'informations sensibles
- Si tu ne connais pas une réponse précise, dis-le honnêtement
- Guide l'utilisateur vers les sections appropriées de l'app
- Pour les questions complexes, suggère de contacter le support


EXEMPLES DE RÉPONSES ATTENDUES :
- "Comment créer une réclamation ?" → Expliquer le processus dans l'app
- "Où est ma commande ?" → Expliquer le suivi de commande
- "Comment retourner un produit ?" → Expliquer la politique de retour
- "Quels sont les délais de livraison ?" → Donner les délais selon le mode
''';

  @override
  void initState() {
    super.initState();
    _initializeBot();
  }

  Future<void> _initializeBot() async {
    debugPrint('🔑 Initialisation du chatbot...');
    _apiKey = ApiConfig.isApiKeyValid ? ApiConfig.geminiApiKey : await _loadApiKeyFromPrefs();
    debugPrint('API Key valide: ${(_apiKey != null && _apiKey!.isNotEmpty)}');

    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('❌ Clé API invalide');
      _showApiKeyError();
      await _askForApiKey();
      return;
    }

    try {
      debugPrint('📡 Création du modèle Gemini...');
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey!,
        generationConfig: GenerationConfig(
          temperature: 0.9,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 2048,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
        ],
      );

      debugPrint('💬 Démarrage de la session de chat...');
      _chat = _model!.startChat();
      debugPrint('✅ Chatbot initialisé avec succès');

      setState(() {
        _messages.add(_ChatMessage(
          text:
              'Bonjour ! 👋\n\nJe suis l\'assistant SmartFIT. Je peux vous aider avec :\n\n' +
                  '• Créer une réclamation\n' +
                  '• Suivre votre commande\n' +
                  '• Informations sur les produits\n' +
                  '• Questions sur la livraison\n' +
                  '• Aide sur votre compte\n\n' +
                  'Comment puis-je vous aider ?',
          isUser: false,
        ));
      });
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation: $e');
      _showInitializationError(e);
    }
  }

  Future<String> _loadApiKeyFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('gemini_api_key') ?? '';
  }

  Future<void> _saveApiKeyToPrefs(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key);
  }

  Future<void> _askForApiKey() async {
    final input = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Configurer la clé Gemini'),
        content: TextField(
          controller: input,
          decoration: const InputDecoration(hintText: 'Collez votre GEMINI_API_KEY'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(input.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _saveApiKeyToPrefs(result);
      _apiKey = result;
      await _initializeBot();
    }
  }

  void _showApiKeyError() {
    setState(() {
      _messages.add(_ChatMessage(
        text: '⚠️ Erreur de configuration\n\n' +
            'La clé API Gemini n\'est pas configurée.\n\n' +
            'Veuillez lancer l\'application avec :\n' +
            'flutter run --dart-define=GEMINI_API_KEY=votre_clé',
        isUser: false,
        isError: true,
      ));
    });
  }

  void _showInitializationError(dynamic error) {
    setState(() {
      _messages.add(_ChatMessage(
        text: '⚠️ Erreur d\'initialisation\n\n' +
            'Impossible de démarrer l\'assistant IA.\n' +
            'Erreur: ${error.toString()}',
        isUser: false,
        isError: true,
      ));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending || _chat == null) {
      debugPrint('⚠️ Impossible d\'envoyer: texte vide ou chat null');
      return;
    }

    final promptWithContext = '''
$assistantContext


Question de l'utilisateur:
$text
''';

    setState(() {
      _isSending = true;
      _messages.add(_ChatMessage(text: text, isUser: true));
      _messages.add(_ChatMessage(text: '', isUser: false));
      _controller.clear();
    });

    _scrollToBottom();

    final int aiIndex = _messages.length - 1;

    try {
      debugPrint('📤 Envoi du message à Gemini...');
      final Stream<GenerateContentResponse> stream =
          _chat!.sendMessageStream(Content.text(promptWithContext));

      final StringBuffer fullResponse = StringBuffer();
      await for (final chunk in stream) {
        final partText = chunk.text ?? '';
        if (partText.isEmpty) continue;

        fullResponse.write(partText);
        setState(() {
          _messages[aiIndex] = _messages[aiIndex].copyWith(
            text: fullResponse.toString(),
          );
        });
        _scrollToBottom();
      }

      if (fullResponse.isEmpty) {
        setState(() {
          _messages[aiIndex] = _messages[aiIndex].copyWith(
            text:
                "Je n'ai pas pu générer de réponse. Pouvez-vous reformuler votre question ?",
          );
        });
      } else {
        debugPrint('✅ Réponse reçue: ${fullResponse.length} caractères');
      }
    } on GenerativeAIException catch (e) {
      debugPrint('❌ Erreur Gemini: ${e.message}');
      setState(() {
        _messages[aiIndex] = _messages[aiIndex].copyWith(
          text: "⚠️ Erreur de l'API Gemini\n\n${_getErrorMessage(e)}",
          isError: true,
        );
      });
    } catch (e) {
      debugPrint('❌ Erreur inattendue: $e');
      setState(() {
        _messages[aiIndex] = _messages[aiIndex].copyWith(
          text:
              "❌ Une erreur inattendue s'est produite.\n\nVeuillez réessayer dans quelques instants.",
          isError: true,
        );
      });
    } finally {
      setState(() {
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  String _getErrorMessage(GenerativeAIException e) {
    if (e.message.contains('API key')) {
      return 'Problème avec la clé API. Vérifiez votre configuration.';
    } else if (e.message.contains('quota')) {
      return 'Quota API dépassé. Veuillez réessayer plus tard.';
    } else if (e.message.contains('safety')) {
      return 'Le contenu a été bloqué pour des raisons de sécurité. Reformulez votre question.';
    } else if (e.message.contains('not found')) {
      return "Le modèle n'est pas disponible. Vérifiez votre configuration.";
    }
    return e.message;
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Actions rapides',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _QuickActionButton(
              icon: Icons.report_problem,
              label: 'Créer une réclamation',
              onTap: () {
                Navigator.pop(context);
                _controller.text = 'Comment créer une réclamation ?';
                _sendMessage();
              },
            ),
            _QuickActionButton(
              icon: Icons.local_shipping,
              label: 'Suivre ma commande',
              onTap: () {
                Navigator.pop(context);
                _controller.text = 'Comment suivre ma commande ?';
                _sendMessage();
              },
            ),
            _QuickActionButton(
              icon: Icons.assignment_return,
              label: 'Retourner un produit',
              onTap: () {
                Navigator.pop(context);
                _controller.text = 'Comment retourner un produit ?';
                _sendMessage();
              },
            ),
            _QuickActionButton(
              icon: Icons.help_outline,
              label: 'Aide générale',
              onTap: () {
                Navigator.pop(context);
                _controller.text = 'Quels services proposez-vous ?';
                _sendMessage();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy, size: 20),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Assistant SmartFIT',
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: 'Actions rapides',
            onPressed: _showQuickActions,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Nouvelle conversation',
            onPressed: () {
              setState(() {
                _messages.clear();
                _initializeBot();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: cs.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Commencez la conversation',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: cs.onSurface.withOpacity(0.6),
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _messages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _MessageBubble(message: msg);
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.2),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _showQuickActions,
                    tooltip: 'Actions rapides',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isSending && _chat != null,
                      decoration: InputDecoration(
                        hintText: "Posez votre question...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: _isSending
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    onPressed: _isSending || _chat == null ? null : _sendMessage,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUser = message.isUser;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;

    Color bubbleColor;
    if (message.isError) {
      bubbleColor = Colors.red.withOpacity(0.1);
    } else if (isUser) {
      bubbleColor = cs.primary.withOpacity(0.12);
    } else {
      bubbleColor = cs.secondary.withOpacity(0.15);
    }

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bubbleColor,
          border: Border.all(
            color: message.isError
                ? Colors.red.withOpacity(0.3)
                : Theme.of(context).dividerColor.withOpacity(0.15),
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    message.isError ? Icons.error_outline : Icons.smart_toy,
                    size: 16,
                    color: message.isError ? Colors.red : cs.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    message.isError ? 'Erreur' : 'Assistant',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: message.isError ? Colors.red : cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            if (!isUser) const SizedBox(height: 6),
            SelectableText(
              message.text.isEmpty ? '...' : message.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
