// lib/services/scraper_service.dart
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:flutter/foundation.dart';

class ScraperService {
  // Headers améliorés pour éviter les blocages
  static const Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
  };

  Future<List<Map<String, dynamic>>> scrapeArticles(String sourceUrl, {int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse(sourceUrl),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 403) {
        debugPrint('⛔ Site bloqué (403): $sourceUrl');
        return [];
      }
      
      if (response.statusCode != 200) {
        debugPrint('⚠️ Erreur ${response.statusCode}: $sourceUrl');
        return [];
      }

      final document = html_parser.parse(response.body);
      final articles = <Map<String, dynamic>>[];

      // Sélecteurs génériques pour articles
      final selectors = [
        'article',
        '.article',
        '[class*="article"]',
        '[class*="story"]',
        '[class*="post"]',
        '[class*="teaser"]',
      ];

      for (var selector in selectors) {
        final elements = document.querySelectorAll(selector);
        
        // Prendre plus d'éléments que nécessaire pour filtrer ensuite
        for (var element in elements.take(limit * 3)) {
          final title = _extractTitle(element);
          final url = _extractUrl(element, sourceUrl);
          final imageUrl = _extractImage(element, sourceUrl);
          final isPremium = _detectPremium(element);
          
          if (title.isNotEmpty && url.isNotEmpty && title.length > 10) {
            articles.add({
              'title': title,
              'url': url,
              'imageUrl': imageUrl,
              'isPremium': isPremium,
            });
            
            // Arrêter si on a assez d'articles
            if (articles.length >= limit) break;
          }
        }
        
        if (articles.length >= limit) break;
      }

      debugPrint('✅ ${articles.length} articles trouvés pour $sourceUrl');
      return articles.take(limit).toList();
    } catch (e) {
      debugPrint('❌ Erreur scraping: $e');
      return [];
    }
  }

  String _extractTitle(Element element) {
    final titleSelectors = [
      'h1', 
      'h2', 
      'h3', 
      '.title', 
      '[class*="title"]',
      '[class*="headline"]',
      'a',
    ];
    
    for (var selector in titleSelectors) {
      final titleElement = element.querySelector(selector);
      if (titleElement != null && titleElement.text.trim().isNotEmpty) {
        final title = titleElement.text.trim();
        if (title.length > 10) {
          return title;
        }
      }
    }
    
    return '';
  }

  String _extractUrl(Element element, String baseUrl) {
    final link = element.querySelector('a');
    if (link == null) return '';
    
    var href = link.attributes['href'] ?? '';
    if (href.isEmpty) return '';
    
    // Ignorer les liens internes (ancres)
    if (href.startsWith('#')) return '';
    
    // Convertir URL relative en absolue
    if (href.startsWith('/')) {
      final uri = Uri.parse(baseUrl);
      href = '${uri.scheme}://${uri.host}$href';
    } else if (!href.startsWith('http')) {
      href = '$baseUrl/$href';
    }
    
    return href;
  }

  String? _extractImage(Element element, String baseUrl) {
    final imageSelectors = [
      'img',
      'picture img',
      '[class*="image"] img',
      '[class*="thumbnail"] img',
      '[class*="media"] img',
      '[class*="photo"] img',
    ];

    for (var selector in imageSelectors) {
      final img = element.querySelector(selector);
      if (img != null) {
        var imgUrl = img.attributes['src'] ?? 
                     img.attributes['data-src'] ?? 
                     img.attributes['data-lazy-src'] ?? 
                     img.attributes['data-original'] ?? '';
        
        if (imgUrl.isNotEmpty) {
          // Ignorer les images data:image
          if (imgUrl.startsWith('data:')) continue;
          
          // Ignorer les très petites images (icônes, etc.)
          if (imgUrl.contains('icon') || imgUrl.contains('logo') || imgUrl.contains('avatar')) {
            continue;
          }
          
          // Convertir URL relative en absolue
          if (imgUrl.startsWith('//')) {
            imgUrl = 'https:$imgUrl';
          } else if (imgUrl.startsWith('/')) {
            final uri = Uri.parse(baseUrl);
            imgUrl = '${uri.scheme}://${uri.host}$imgUrl';
          } else if (!imgUrl.startsWith('http')) {
            continue;
          }
          
          return imgUrl;
        }
      }
    }
    
    return null;
  }

  bool _detectPremium(Element element) {
    final text = element.text.toLowerCase();
    final html = element.outerHtml.toLowerCase();
    
    final premiumKeywords = [
      'premium',
      'réservé aux abonnés',
      'réservé abonnés',
      'subscriber',
      'paywall',
      'exclusive',
      'membres uniquement',
      'accès premium',
      'contenu exclusif',
      'abonné',
    ];
    
    for (var keyword in premiumKeywords) {
      if (text.contains(keyword) || html.contains(keyword)) {
        return true;
      }
    }
    
    final classes = element.classes.join(' ').toLowerCase();
    if (classes.contains('premium') || 
        classes.contains('subscriber') || 
        classes.contains('locked') ||
        classes.contains('paywall')) {
      return true;
    }
    
    return false;
  }

  Future<String> extractArticleContent(String articleUrl) async {
    try {
      final response = await http.get(
        Uri.parse(articleUrl),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode != 200) return '';

      final document = html_parser.parse(response.body);
      
      // Supprimer les éléments non pertinents
      document.querySelectorAll('script, style, nav, header, footer, aside, .ad, .advertisement').forEach((e) => e.remove());
      
      final contentSelectors = [
        'article',
        '[class*="content"]',
        '[class*="article-body"]',
        '[class*="article-content"]',
        'main',
        '.post-content',
        '[itemprop="articleBody"]',
      ];
      
      for (var selector in contentSelectors) {
        final content = document.querySelector(selector);
        if (content != null) {
          final paragraphs = content.querySelectorAll('p');
          final text = paragraphs.map((p) => p.text.trim()).where((t) => t.isNotEmpty && t.length > 20).join('\n\n');
          if (text.length > 200) {
            return text;
          }
        }
      }
      
      // Fallback
      final allParagraphs = document.querySelectorAll('p');
      return allParagraphs.map((p) => p.text.trim()).where((t) => t.isNotEmpty && t.length > 20).take(15).join('\n\n');
      
    } catch (e) {
      debugPrint('❌ Erreur extraction contenu: $e');
      return '';
    }
  }
}