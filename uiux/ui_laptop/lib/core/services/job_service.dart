import '../models/report.dart';
import '../models/research_job.dart';
import '../models/source_document.dart';
import 'api_client.dart';

/// Maps all UI calls to the FastAPI backend endpoints.
///
/// Backend base prefix: /jobs
///   POST  /jobs               → create job
///   GET   /jobs               → list all jobs
///   GET   /jobs/{id}          → job status + metadata
///   GET   /jobs/{id}/report   → full generated report
///   GET   /jobs/{id}/sources  → retrieved source documents
///   POST  /jobs/{id}/chat     → RAG Q&A
class JobService {
  JobService(this._client);

  final ApiClient _client;

  Future<ResearchJob> createJob({
    required String topic,
    required int depth,
  }) async {
    final response = await _client.post('/jobs', data: {
      'topic': topic,
      'depth_minutes': depth,
    });
    return ResearchJob.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ResearchJob> fetchJob(int jobId) async {
    final response = await _client.get('/jobs/$jobId');
    return ResearchJob.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ResearchJob>> fetchJobs() async {
    final response = await _client.get('/jobs');
    final data = response.data as List<dynamic>;
    return data
        .map((item) => ResearchJob.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<JobReport> fetchReport(int jobId) async {
    final response = await _client.get('/jobs/$jobId/report');
    final data = response.data as Map<String, dynamic>;
    data['job_id'] ??= jobId;
    return JobReport.fromJson(data);
  }

  Future<List<SourceDocument>> fetchSources(int jobId) async {
    final response = await _client.get('/jobs/$jobId/sources');
    final data = response.data as Map<String, dynamic>;
    final sources = data['sources'] as List<dynamic>? ?? [];
    return sources
        .map((item) =>
            SourceDocument.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ChatResponse> chatWithJobDetailed(
      int jobId, String question) async {
    final response = await _client.post('/jobs/$jobId/chat', data: {
      'question': question,
    });
    return ChatResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<String> chatWithJob(int jobId, String question) async {
    final result = await chatWithJobDetailed(jobId, question);
    return result.answer;
  }
}
