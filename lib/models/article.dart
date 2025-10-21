class Article {
  final int? id;
  final String sourceId;
  final String title;
  final String url;
  final DateTime publishedAt;
  final bool isAnalyzed;
  final String? summary;
  final List<String>? highlights;
  final List<String>? keywords;
  final String? tone;
  final String? fullContent;
  final String? imageUrl;
  final bool isPremium;
  final bool isDeleted;

  Article({
    this.id,
    required this.sourceId,
    required this.title,
    required this.url,
    required this.publishedAt,
    this.isAnalyzed = false,
    this.summary,
    this.highlights,
    this.keywords,
    this.tone,
    this.fullContent,
    this.imageUrl,
    this.isPremium = false,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sourceId': sourceId,
      'title': title,
      'url': url,
      'publishedAt': publishedAt.toIso8601String(),
      'isAnalyzed': isAnalyzed ? 1 : 0,
      'summary': summary,
      'highlights': highlights?.join('|||'),
      'keywords': keywords?.join(','),
      'tone': tone,
      'fullContent': fullContent,
      'imageUrl': imageUrl,
      'isPremium': isPremium ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
    };
  }

  factory Article.fromMap(Map<String, dynamic> map) {
    return Article(
      id: map['id'],
      sourceId: map['sourceId'],
      title: map['title'],
      url: map['url'],
      publishedAt: DateTime.parse(map['publishedAt']),
      isAnalyzed: map['isAnalyzed'] == 1,
      summary: map['summary'],
      highlights: map['highlights'] != null 
          ? (map['highlights'] as String).split('|||')
          : null,
      keywords: map['keywords'] != null
          ? (map['keywords'] as String).split(',')
          : null,
      tone: map['tone'],
      fullContent: map['fullContent'],
      imageUrl: map['imageUrl'],
      isPremium: map['isPremium'] == 1,
      isDeleted: map['isDeleted'] == 1,
    );
  }

  Article copyWith({
    int? id,
    String? sourceId,
    String? title,
    String? url,
    DateTime? publishedAt,
    bool? isAnalyzed,
    String? summary,
    List<String>? highlights,
    List<String>? keywords,
    String? tone,
    String? fullContent,
    String? imageUrl,
    bool? isPremium,
    bool? isDeleted,
  }) {
    return Article(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      title: title ?? this.title,
      url: url ?? this.url,
      publishedAt: publishedAt ?? this.publishedAt,
      isAnalyzed: isAnalyzed ?? this.isAnalyzed,
      summary: summary ?? this.summary,
      highlights: highlights ?? this.highlights,
      keywords: keywords ?? this.keywords,
      tone: tone ?? this.tone,
      fullContent: fullContent ?? this.fullContent,
      imageUrl: imageUrl ?? this.imageUrl,
      isPremium: isPremium ?? this.isPremium,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}