class ResearchJob {
  const ResearchJob({
    required this.id,
    required this.topic,
    required this.status,
    required this.progress,
    this.depthMinutes,
    this.createdAt,
    this.updatedAt,
    this.stage,
  });

  final int id;
  final String topic;
  final String status;
  final int progress;
  final int? depthMinutes;
  final String? createdAt;
  final String? updatedAt;
  final String? stage;

  factory ResearchJob.fromJson(Map<String, dynamic> json) {
    return ResearchJob(
      id: (json['id'] as num).toInt(),
      topic: json['topic'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      depthMinutes: (json['depth_minutes'] as num?)?.toInt(),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      stage: json['stage'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'topic': topic,
        'status': status,
        'progress': progress,
        'depth_minutes': depthMinutes,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'stage': stage,
      };

  ResearchJob copyWith({
    int? id,
    String? topic,
    String? status,
    int? progress,
    int? depthMinutes,
    String? createdAt,
    String? updatedAt,
    String? stage,
  }) {
    return ResearchJob(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      depthMinutes: depthMinutes ?? this.depthMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      stage: stage ?? this.stage,
    );
  }
}
