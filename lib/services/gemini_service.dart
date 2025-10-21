// lib/services/gemini_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeminiService {
  // Utilise gemini-2.5-flash (nouveau modèle stable, plus rapide et moins cher)
  static const String baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const String model = 'gemini-2.5-flash';
  final String apiKey;

  GeminiService({required this.apiKey});

  Future<Map<String, dynamic>?> analyzeArticle(String articleContent, String articleTitle) async {
    final prompt = '''
Analyse cet article de presse et fournis une réponse STRICTEMENT au format JSON suivant (ne réponds qu'avec du JSON valide, sans texte supplémentaire, sans balises markdown) :

{
  "resume": "Un résumé en 2-3 phrases maximum",
  "highlights": ["point clé 1", "point clé 2", "point clé 3", "point clé 4"],
  "mots_cles": ["mot1", "mot2", "mot3", "mot4", "mot5"],
  "ton": "informatif ou positif ou urgent ou opinion"
}

IMPORTANT: Réponds UNIQUEMENT avec le JSON brut, rien d'autre. Pas de texte avant ou après, pas de ```json.

Titre: $articleTitle

Contenu:
$articleContent
''';

    try {
      final url = '$baseUrl/$model:generateContent?key=$apiKey';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.4,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Vérifier si la réponse contient des candidats
        if (data['candidates'] == null || data['candidates'].isEmpty) {
          debugPrint('⚠️ Aucun candidat dans la réponse Gemini');
          return null;
        }
        
        // Vérifier le finish reason
        final finishReason = data['candidates'][0]['finishReason'];
        if (finishReason == 'SAFETY') {
          debugPrint('⚠️ Réponse bloquée pour raisons de sécurité');
          return null;
        }
        
        // Extraire le texte de la première réponse
        final candidate = data['candidates'][0];
        if (candidate['content'] == null || 
            candidate['content']['parts'] == null || 
            candidate['content']['parts'].isEmpty) {
          debugPrint('⚠️ Réponse vide de Gemini');
          return null;
        }
        
        final textContent = candidate['content']['parts'][0]['text'];
        
        // Nettoyer la réponse pour extraire le JSON
        String cleanedJson = textContent.trim();
        
        // Supprimer les balises markdown si présentes
        cleanedJson = cleanedJson.replaceAll(RegExp(r'^```json\s*'), '');
        cleanedJson = cleanedJson.replaceAll(RegExp(r'^```\s*'), '');
        cleanedJson = cleanedJson.replaceAll(RegExp(r'\s*```$'), '');
        cleanedJson = cleanedJson.trim();
        
        // Extraire uniquement le JSON valide
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleanedJson);
        if (jsonMatch == null) {
          debugPrint('⚠️ Aucun JSON trouvé dans la réponse: $cleanedJson');
          return null;
        }
        
        cleanedJson = jsonMatch.group(0)!;
        
        // Nettoyer les sauts de ligne non échappés dans les strings JSON
        cleanedJson = _fixJsonLineBreaks(cleanedJson);
        
        try {
          final analysisResult = jsonDecode(cleanedJson);
          
          // Valider la structure
          if (analysisResult['resume'] == null || 
              analysisResult['highlights'] == null || 
              analysisResult['mots_cles'] == null) {
            debugPrint('⚠️ Structure JSON invalide');
            return null;
          }
          
          return analysisResult;
        } catch (e) {
          debugPrint('❌ Erreur parsing JSON: $e');
          debugPrint('JSON reçu: $cleanedJson');
          return null;
        }
      } else if (response.statusCode == 400) {
        debugPrint('❌ Erreur 400 - Requête invalide: ${response.body}');
        return null;
      } else if (response.statusCode == 403) {
        debugPrint('❌ Erreur 403 - Clé API invalide ou quota dépassé');
        return null;
      } else if (response.statusCode == 404) {
        debugPrint('❌ Erreur 404 - Modèle non trouvé: ${response.body}');
        return null;
      } else {
        debugPrint('❌ Erreur API Gemini: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Erreur analyse Gemini: $e');
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
      
      // Pause pour respecter le rate limiting (60 requêtes/minute)
      await Future.delayed(const Duration(seconds: 1));
    }
    
    return results;
  }
  
  // Méthode helper pour vérifier si la clé API est valide
  Future<bool> validateApiKey() async {
    try {
      final url = '$baseUrl/$model:generateContent?key=$apiKey';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Test'}
              ]
            }
          ]
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // Méthode helper pour corriger les sauts de ligne dans le JSON
  String _fixJsonLineBreaks(String json) {
    // Remplacer les sauts de ligne non échappés dans les strings JSON
    // par des espaces
    final buffer = StringBuffer();
    bool inString = false;
    bool escapeNext = false;
    
    for (int i = 0; i < json.length; i++) {
      final char = json[i];
      
      if (escapeNext) {
        buffer.write(char);
        escapeNext = false;
        continue;
      }
      
      if (char == '\\') {
        buffer.write(char);
        escapeNext = true;
        continue;
      }
      
      if (char == '"') {
        buffer.write(char);
        inString = !inString;
        continue;
      }
      
      // Remplacer les sauts de ligne dans les strings par des espaces
      if (inString && (char == '\n' || char == '\r')) {
        buffer.write(' ');
        continue;
      }
      
      buffer.write(char);
    }
    
    return buffer.toString();
  }
}