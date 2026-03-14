/// Mirrors one entry in `GET /jobs/{id}/sources → sources[]`.
///
/// ```json
/// { "id": 1, "title": "...", "url": "...", "snippet": "...", "source_type": "wikipedia" }
/// ```
class SourceDocument {
  final int id;
  final String title;
  final String url;

  /// First 240 characters of the document content (pre-truncated by backend).
  final String snippet;

  /// Origin of the source: "wikipedia" | "arxiv" | "unknown"
  final String sourceType;

  const SourceDocument({
    required this.id,
    required this.title,
    required this.url,
    required this.snippet,
    required this.sourceType,
  });

  factory SourceDocument.fromJson(Map<String, dynamic> json) {
    return SourceDocument(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      snippet: json['snippet'] as String? ?? '',
      sourceType: json['source_type'] as String? ?? 'web',
    );
  }
}
