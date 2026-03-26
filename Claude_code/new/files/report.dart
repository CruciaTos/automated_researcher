import 'citation.dart';

class JobReport {
  const JobReport({
    required this.jobId,
    required this.topic,
    required this.status,
    this.report,
    this.citations,
    this.modelUsed,
  });

  final int jobId;
  final String topic;
  final String status;
  final String? report;
  final List<Citation>? citations;
  final String? modelUsed;

  factory JobReport.fromJson(Map<String, dynamic> json) {
    final rawCitations = json['citations'] as List<dynamic>?;
    return JobReport(
      jobId: json['job_id'] as int? ?? 0,
      topic: json['topic'] as String? ?? '',
      status: json['status'] as String? ?? '',
      report: json['report'] as String?,
      modelUsed: json['model_used'] as String?,
      citations: rawCitations
          ?.map((c) => Citation.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ChatResponse {
  const ChatResponse({
    required this.answer,
    this.citations,
  });

  final String answer;
  final List<Citation>? citations;

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    final rawCitations = json['citations'] as List<dynamic>?;
    return ChatResponse(
      answer: json['answer'] as String? ?? '',
      citations: rawCitations
          ?.map((c) => Citation.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
