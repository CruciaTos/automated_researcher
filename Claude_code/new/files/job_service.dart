import '../models/report.dart';
import '../models/research_job.dart';
import '../models/source_document.dart';
import 'api_client.dart';

/// Maps all UI calls to the FastAPI backend endpoints.
class JobService {
  JobService(this._client);

  final ApiClient _client;

  Future<ResearchJob> createJob({
    required String topic,
    required int depth,
    String? modelOverride,
  }) async {
    final body = <String, dynamic>{
      'topic': topic,
      'depth_minutes': depth,
    };
    if (modelOverride != null && modelOverride.isNotEmpty) {
      body['model_override'] = modelOverride;
    }
    final response = await _client.post('/jobs', data: body);
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
    return ChatResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> chatWithJob(int jobId, String question) async {
    final result = await chatWithJobDetailed(jobId, question);
    return result.answer;
  }

  Future<Map<String, dynamic>> fetchAvailableModels() async {
    final response = await _client.get('/health/models');
    return response.data as Map<String, dynamic>;
  }
}
