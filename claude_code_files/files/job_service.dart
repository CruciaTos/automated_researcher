import '../models/report.dart';
import '../models/research_job.dart';
import '../models/source_document.dart';
import 'api_client.dart';

class JobService {
  JobService(this._client);

  final ApiClient _client;

  /// POST /research — create a new research job
  Future<ResearchJob> createJob({
    required String topic,
    required int depth,
  }) async {
    final response = await _client.post('/research', data: {
      'topic': topic,
      'depth': depth,
    });
    // Backend returns { "job_id": "string" } — wrap into ResearchJob shape
    final data = response.data as Map<String, dynamic>;
    return ResearchJob(
      id: int.tryParse(data['job_id']?.toString() ?? '0') ?? 0,
      topic: topic,
      status: 'running',
      progress: 0,
      depthMinutes: depth,
    );
  }

  /// GET /research/{job_id}/status — poll job progress
  Future<ResearchJob> fetchJob(int jobId) async {
    final response = await _client.get('/research/$jobId/status');
    final data = response.data as Map<String, dynamic>;
    return ResearchJob(
      id: jobId,
      topic: data['topic'] as String? ?? '',
      status: data['status'] as String? ?? 'running',
      progress: (data['progress'] as num?)?.toInt() ?? 0,
      stage: data['stage'] as String?,
    );
  }

  /// GET /research/history — list all jobs
  Future<List<ResearchJob>> fetchJobs() async {
    final response = await _client.get('/research/history');
    final data = response.data as List<dynamic>;
    return data.map((item) {
      final map = item as Map<String, dynamic>;
      return ResearchJob(
        id: int.tryParse(map['job_id']?.toString() ?? '0') ?? 0,
        topic: map['topic'] as String? ?? '',
        status: map['status'] as String? ?? 'completed',
        progress: map['status'] == 'completed' ? 100 : 0,
        createdAt: map['created_at'] as String?,
      );
    }).toList();
  }

  /// GET /research/{job_id}/report — fetch the full report
  Future<JobReport> fetchReport(int jobId) async {
    final response = await _client.get('/research/$jobId/report');
    final data = response.data as Map<String, dynamic>;
    // Inject job_id if not present
    data['job_id'] ??= jobId;
    return JobReport.fromJson(data);
  }

  /// GET /jobs/{job_id}/sources — fetch source documents (non-spec endpoint)
  Future<List<SourceDocument>> fetchSources(int jobId) async {
    final response = await _client.get('/jobs/$jobId/sources');
    final data = response.data as Map<String, dynamic>;
    final sources = data['sources'] as List<dynamic>? ?? [];
    return sources
        .map((item) => SourceDocument.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// POST /research/{job_id}/ask — RAG chat, returns answer + citations
  Future<ChatResponse> chatWithJobDetailed(
      int jobId, String question) async {
    final response = await _client.post('/research/$jobId/ask', data: {
      'question': question,
    });
    return ChatResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Simplified chat that returns only the answer string
  Future<String> chatWithJob(int jobId, String question) async {
    final result = await chatWithJobDetailed(jobId, question);
    return result.answer;
  }
}
