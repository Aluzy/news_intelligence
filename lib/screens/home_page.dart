// lib/screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/source.dart';
import '../models/article.dart';
import '../services/database_service.dart';
import '../services/scraper_service.dart';
import '../services/ai_service.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _dbService = DatabaseService.instance;
  final ScraperService _scraperService = ScraperService();
  AIService? _aiService;
  
  List<NewsSource> _sources = [];
  List<Article> _articles = [];
  bool _isLoading = false;
  int _articlesPerSource = 10;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    _aiService = await AIService.create();
    final prefs = await SharedPreferences.getInstance();
    _articlesPerSource = prefs.getInt('articles_per_source') ?? 10;
    
    final sources = await _dbService.getAllSources();
    final articles = await _dbService.getAllArticles();
    
    setState(() {
      _sources = sources;
      _articles = articles;
    });
    
    if (_sources.isEmpty) {
      await _addDefaultSources();
    }
  }

  Future<void> _addDefaultSources() async {
    final defaultSources = [
      NewsSource(name: 'Le Monde', url: 'https://www.lemonde.fr'),
      NewsSource(name: 'Les Échos', url: 'https://www.lesechos.fr'),
    ];
    
    for (var source in defaultSources) {
      await _dbService.createSource(source);
    }
    
    await _loadData();
  }

  Future<void> _refreshArticles() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      for (var source in _sources.where((s) => s.isActive)) {
        final scrapedArticles = await _scraperService.scrapeArticles(
          source.url,
          limit: _articlesPerSource,
        );
        
        for (var scraped in scrapedArticles) {
          final article = Article(
            sourceId: source.name,
            title: scraped['title']!,
            url: scraped['url']!,
            publishedAt: DateTime.now(),
            imageUrl: scraped['imageUrl'],
            isPremium: scraped['isPremium'] ?? false,
          );
          
          await _dbService.createArticle(article);
        }
      }
      
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_articles.length} articles chargés')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _analyzeArticle(Article article) async {
    if (_aiService == null || !_aiService!.isConfigured()) {
      _openSettings();
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final content = await _scraperService.extractArticleContent(article.url);
      
      if (content.isEmpty) {
        throw Exception('Impossible d\'extraire le contenu');
      }
      
      final analysis = await _aiService!.analyzeArticle(content, article.title);
      
      if (analysis != null) {
        final updatedArticle = article.copyWith(
          isAnalyzed: true,
          summary: analysis['resume'],
          highlights: List<String>.from(analysis['highlights']),
          keywords: List<String>.from(analysis['mots_cles']),
          tone: analysis['ton'],
          fullContent: content,
        );
        
        await _dbService.updateArticle(updatedArticle);
        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Article analysé par ${_aiService!.getApiName()}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'analyse: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteArticle(Article article) async {
    final updatedArticle = article.copyWith(isDeleted: true);
    await _dbService.updateArticle(updatedArticle);
    await _loadData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article supprimé')),
      );
    }
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
    
    if (result == true) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('News Intelligence', style: TextStyle(fontSize: 18)),
                Text(
                  'Veille augmentée par IA',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshArticles,
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Articles'),
            Tab(text: 'Sources'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildArticlesTab(),
          _buildSourcesTab(),
        ],
      ),
    );
  }

  Widget _buildArticlesTab() {
    if (_articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.article_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Aucun article'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _refreshArticles,
              icon: const Icon(Icons.refresh),
              label: const Text('Charger les articles'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _articles.length,
      itemBuilder: (context, index) {
        final article = _articles[index];
        final source = _sources.firstWhere(
          (s) => s.name == article.sourceId,
          orElse: () => NewsSource(name: article.sourceId, url: ''),
        );
        
        return ArticleCard(
          article: article,
          source: source,
          onAnalyze: () => _analyzeArticle(article),
          onDelete: () => _showDeleteConfirmation(article),
        );
      },
    );
  }

  void _showDeleteConfirmation(Article article) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'article'),
        content: const Text('Voulez-vous vraiment supprimer cet article ? Il ne réapparaîtra pas lors du prochain rafraîchissement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteArticle(article);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showAddSourceDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une source'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _sources.length,
            itemBuilder: (context, index) {
              final source = _sources[index];
              return SourceCard(
                source: source,
                onToggle: () async {
                  final updated = source.copyWith(isActive: !source.isActive);
                  await _dbService.updateSource(updated);
                  await _loadData();
                },
                onDelete: () async {
                  await _dbService.deleteSource(source.id!);
                  await _loadData();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddSourceDialog() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'URL'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && urlController.text.isNotEmpty) {
                final source = NewsSource(
                  name: nameController.text,
                  url: urlController.text,
                );
                await _dbService.createSource(source);
                await _loadData();
                if (mounted && context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// ==================== WIDGETS ====================

class ArticleCard extends StatefulWidget {
  final Article article;
  final NewsSource source;
  final VoidCallback onAnalyze;
  final VoidCallback onDelete;

  const ArticleCard({
    super.key,
    required this.article,
    required this.source,
    required this.onAnalyze,
    required this.onDelete,
  });

  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard> {
  bool _isExpanded = false;
  bool _showDeleteIcon = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        setState(() => _showDeleteIcon = true);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de l'article
            if (widget.article.imageUrl != null)
              Stack(
                children: [
                  Image.network(
                    widget.article.imageUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                  if (widget.article.isPremium)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium, size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Premium',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec source et bouton supprimer
                  Row(
                    children: [
                      // Logo de la source
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          widget.source.getLogoUrl(),
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.language,
                            size: 20,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.article.sourceId,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${_formatDate(widget.article.publishedAt)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const Spacer(),
                      if (_showDeleteIcon)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: widget.onDelete,
                        )
                      else if (widget.article.isAnalyzed)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEFF6FF), Color(0xFFF3E8FF)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, size: 12, color: Colors.blue),
                              SizedBox(width: 4),
                              Text(
                                'Analysé',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Titre
                  Text(
                    widget.article.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  if (widget.article.isAnalyzed) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.article.summary ?? '',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    
                    // Mots-clés avec scroll horizontal
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ...?widget.article.keywords?.map(
                            (kw) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Chip(
                                label: Text(kw, style: const TextStyle(fontSize: 12)),
                                backgroundColor: Colors.grey[200],
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                          if (widget.article.tone != null)
                            Chip(
                              label: Text(
                                widget.article.tone!,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: _getToneColor(widget.article.tone!),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => setState(() => _isExpanded = !_isExpanded),
                          icon: Icon(_isExpanded ? Icons.expand_less : Icons.trending_up),
                          label: Text(
                            _isExpanded
                                ? 'Masquer les highlights'
                                : 'Voir les highlights (${widget.article.highlights?.length ?? 0})',
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _launchUrl(widget.article.url),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Article complet'),
                        ),
                      ],
                    ),
                    
                    if (_isExpanded && widget.article.highlights != null) ...[
                      const Divider(),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEFF6FF), Color(0xFFF3E8FF)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.trending_up, size: 16, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'Points clés à retenir',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...widget.article.highlights!.map(
                              (h) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                    Expanded(child: Text(h)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Article non analysé',
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: widget.onAnalyze,
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('Analyser'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getToneColor(String tone) {
    switch (tone.toLowerCase()) {
      case 'informatif':
        return const Color(0xFFDEEBFF);
      case 'positif':
        return const Color(0xFFD4EDDA);
      case 'urgent':
        return const Color(0xFFF8D7DA);
      case 'opinion':
        return const Color(0xFFE7D4F5);
      default:
        return Colors.grey[200]!;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}j';
    }
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class SourceCard extends StatelessWidget {
  final NewsSource source;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const SourceCard({
    super.key,
    required this.source,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: source.isActive ? Colors.green : Colors.grey[300],
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                source.getLogoUrl(),
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.language,
                  size: 32,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        title: Text(source.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          source.url,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: source.isActive,
              onChanged: (_) => onToggle(),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Supprimer la source'),
                    content: Text('Voulez-vous supprimer "${source.name}" ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onDelete();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}