/// Mirrors the response of `GET /jobs/{id}/report`.
///
/// ```json
/// { "job_id": 1, "topic": "...", "status": "completed", "report": "..." }
/// ```
class JobReport {
  final int jobId;
  final String topic;
  final String status;

  /// The generated report text. Null when the job has not completed yet.
  final String? report;

  const JobReport({
    required this.jobId,
    required this.topic,
    required this.status,
    this.report,
  });

  factory JobReport.fromJson(Map<String, dynamic> json) {
    return JobReport(
      jobId: (json['job_id'] as num).toInt(),
      topic: json['topic'] as String? ?? '',
      status: json['status'] as String? ?? '',
      report: json['report'] as String?,
    );
  }
}
