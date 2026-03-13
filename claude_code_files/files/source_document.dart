class SourceDocument {
  const SourceDocument({
    required this.id,
    required this.title,
    required this.url,
    required this.snippet,
    required this.sourceType,
    this.domain,
    this.fetchedAt,
  });

  final int id;
  final String title;
  final String url;
  final String snippet;
  final String sourceType;
  final String? domain;
  final String? fetchedAt;

  factory SourceDocument.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String? ?? '';
    String domain = json['domain'] as String? ?? '';
    if (domain.isEmpty && url.isNotEmpty) {
      try {
        domain = Uri.parse(url).host.replaceFirst('www.', '');
      } catch (_) {}
    }

    return SourceDocument(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      url: url,
      snippet: json['snippet'] as String? ?? json['summary'] as String? ?? '',
      sourceType: json['source_type'] as String? ?? 'web',
      domain: domain,
      fetchedAt: json['fetched_at'] as String?,
    );
  }
}
