class SourceDocument {
  const SourceDocument({
    required this.id,
    required this.title,
    required this.url,
    required this.snippet,
    this.sourceType,
  });

  final int id;
  final String title;
  final String url;
  final String snippet;
  final String? sourceType;

  /// Derived: hostname extracted from the URL for display.
  String? get domain {
    try {
      final host = Uri.parse(url).host;
      return host.isEmpty ? null : host.replaceFirst('www.', '');
    } catch (_) {
      return null;
    }
  }

  factory SourceDocument.fromJson(Map<String, dynamic> json) {
    return SourceDocument(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      snippet: json['snippet'] as String? ?? '',
      sourceType: json['source_type'] as String?,
    );
  }
}
