/// Mirrors the backend `JobResponse` Pydantic schema.
///
/// Backend fields (snake_case) → Dart fields (camelCase).
class ResearchJob {
  final int id;
  final String topic;

  /// Corresponds to `depth_minutes` in the backend.
  final int depthMinutes;

  /// Pipeline stage: queued | retrieving_sources | fetching_documents |
  /// chunking_documents | embedding_documents | drafting_outline |
  /// writing_report | completed | failed
  final String status;

  /// Completion percentage 0–100.
  final int progress;

  /// The generated report text — non-null only when status == 'completed'.
  final String? resultReport;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const ResearchJob({
    required this.id,
    required this.topic,
    required this.depthMinutes,
    required this.status,
    required this.progress,
    this.resultReport,
    required this.createdAt,
    this.updatedAt,
  });

  factory ResearchJob.fromJson(Map<String, dynamic> json) {
    return ResearchJob(
      id: (json['id'] as num).toInt(),
      topic: json['topic'] as String? ?? '',
      depthMinutes: (json['depth_minutes'] as num?)?.toInt() ?? 5,
      status: json['status'] as String? ?? 'queued',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      resultReport: json['result_report'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'topic': topic,
        'depth_minutes': depthMinutes,
        'status': status,
        'progress': progress,
        'result_report': resultReport,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  ResearchJob copyWith({
    String? status,
    int? progress,
    String? resultReport,
  }) =>
      ResearchJob(
        id: id,
        topic: topic,
        depthMinutes: depthMinutes,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        resultReport: resultReport ?? this.resultReport,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
