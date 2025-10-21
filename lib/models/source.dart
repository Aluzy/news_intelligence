class NewsSource {
  final int? id;
  final String name;
  final String url;
  final bool isActive;
  final DateTime createdAt;
  final String? logoUrl;

  NewsSource({
    this.id,
    required this.name,
    required this.url,
    this.isActive = true,
    DateTime? createdAt,
    this.logoUrl,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'logoUrl': logoUrl,
    };
  }

  factory NewsSource.fromMap(Map<String, dynamic> map) {
    return NewsSource(
      id: map['id'],
      name: map['name'],
      url: map['url'],
      isActive: map['isActive'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      logoUrl: map['logoUrl'],
    );
  }

  NewsSource copyWith({
    int? id,
    String? name,
    String? url,
    bool? isActive,
    DateTime? createdAt,
    String? logoUrl,
  }) {
    return NewsSource(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }

  // Méthode helper pour obtenir le logo depuis le domaine
  String getLogoUrl() {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return logoUrl!;
    }
    // Fallback: utiliser Google Favicon API
    final uri = Uri.parse(url);
    return 'https://www.google.com/s2/favicons?domain=${uri.host}&sz=64';
  }
}
