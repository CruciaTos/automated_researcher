import 'citation.dart';

class JobReport {
  const JobReport({
    required this.jobId,
    required this.topic,
    this.report,
    this.citations,
    this.createdAt,
  });

  final int jobId;
  final String topic;
  final String? report;
  final List<Citation>? citations;
  final String? createdAt;

  factory JobReport.fromJson(Map<String, dynamic> json) {
    final citationsRaw = json['citations'] as List<dynamic>?;
    return JobReport(
      jobId: (json['job_id'] as num?)?.toInt() ?? 0,
      topic: json['topic'] as String? ?? json['title'] as String? ?? '',
      report: json['report_text'] as String? ?? json['report'] as String?,
      citations: citationsRaw
          ?.map((c) => Citation.fromJson(c as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] as String?,
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
    final citationsRaw = json['citations'] as List<dynamic>?;
    return ChatResponse(
      answer: json['answer'] as String? ?? '',
      citations: citationsRaw
          ?.map((c) => Citation.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
