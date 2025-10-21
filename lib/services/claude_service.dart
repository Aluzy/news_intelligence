// lib/services/claude_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ClaudeService {
  static const String apiUrl = 'https://api.anthropic.com/v1/messages';
  final String apiKey;

  ClaudeService({required this.apiKey});

  Future<Map<String, dynamic>?> analyzeArticle(String articleContent, String articleTitle) async {
    final prompt = '''
Analyse cet article de presse et fournis une réponse STRICTEMENT au format JSON suivant (ne réponds qu'avec du JSON valide, sans texte supplémentaire) :

{
  "resume": "Un résumé en 2-3 phrases maximum",
  "highlights": ["point clé 1", "point clé 2", "point clé 3", "point clé 4"],
  "mots_cles": ["mot1", "mot2", "mot3", "mot4", "mot5"],
  "ton": "informatif ou positif ou urgent ou opinion"
}

IMPORTANT: Réponds UNIQUEMENT avec le JSON, rien d'autre. Pas de texte avant ou après.

Titre: $articleTitle

Contenu:
$articleContent
''';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 1000,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final textContent = data['content'][0]['text'];
        
        // Nettoyer la réponse pour extraire le JSON
        String cleanedJson = textContent.trim();
        cleanedJson = cleanedJson.replaceAll(RegExp(r'^```json\s*'), '');
        cleanedJson = cleanedJson.replaceAll(RegExp(r'\s*```$'), '');
        cleanedJson = cleanedJson.trim();
        
        final analysisResult = jsonDecode(cleanedJson);
        return analysisResult;
      } else {
        debugPrint('Erreur API Claude: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur analyse Claude: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>?>> analyzeMultipleArticles(
    List<Map<String, String>> articles,
  ) async {
    final results = <Map<String, dynamic>?>[];
    
    for (var article in articles) {
      final result = await analyzeArticle(
        article['content'] ?? '',
        article['title'] ?? '',
      );
      results.add(result);
      
      // Pause pour éviter rate limiting
      await Future.delayed(const Duration(seconds: 1));
    }
    
    return results;
  }
}