class ResearchJob {
  const ResearchJob({
    required this.id,
    required this.topic,
    required this.status,
    required this.progress,
    required this.depthMinutes,
    this.resultReport,
    this.modelOverride,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String topic;
  final String status;
  final int progress;
  final int depthMinutes;
  final String? resultReport;
  final String? modelOverride;
  final String? createdAt;
  final String? updatedAt;

  factory ResearchJob.fromJson(Map<String, dynamic> json) {
    return ResearchJob(
      id: json['id'] as int,
      topic: json['topic'] as String,
      status: json['status'] as String,
      progress: json['progress'] as int? ?? 0,
      depthMinutes: json['depth_minutes'] as int? ?? 5,
      resultReport: json['result_report'] as String?,
      modelOverride: json['model_override'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
