class Citation {
  const Citation({
    required this.id,
    required this.title,
    required this.url,
  });

  final int id;
  final String title;
  final String url;

  factory Citation.fromJson(Map<String, dynamic> json) {
    return Citation(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }
}
