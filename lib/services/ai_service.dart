// lib/services/ai_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'gemini_service.dart';
import 'claude_service.dart';

class AIService {
  static Future<AIService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedApi = prefs.getString('selected_api') ?? 'gemini';
    final apiKey = prefs.getString('${selectedApi}_api_key') ?? '';
    
    return AIService._(selectedApi, apiKey);
  }

  final String apiType;
  final String apiKey;
  GeminiService? _geminiService;
  ClaudeService? _claudeService;

  AIService._(this.apiType, this.apiKey) {
    if (apiType == 'gemini' && apiKey.isNotEmpty) {
      _geminiService = GeminiService(apiKey: apiKey);
    } else if (apiType == 'claude' && apiKey.isNotEmpty) {
      _claudeService = ClaudeService(apiKey: apiKey);
    }
  }

  bool isConfigured() {
    return apiKey.isNotEmpty && 
           (_geminiService != null || _claudeService != null);
  }

  String getApiName() {
    return apiType == 'gemini' ? 'Gemini' : 'Claude';
  }

  Future<Map<String, dynamic>?> analyzeArticle(String content, String title) async {
    if (apiType == 'gemini' && _geminiService != null) {
      return await _geminiService!.analyzeArticle(content, title);
    } else if (apiType == 'claude' && _claudeService != null) {
      return await _claudeService!.analyzeArticle(content, title);
    }
    return null;
  }

  Future<List<Map<String, dynamic>?>> analyzeMultipleArticles(
    List<Map<String, String>> articles,
  ) async {
    if (apiType == 'gemini' && _geminiService != null) {
      return await _geminiService!.analyzeMultipleArticles(articles);
    } else if (apiType == 'claude' && _claudeService != null) {
      return await _claudeService!.analyzeMultipleArticles(articles);
    }
    return [];
  }
}