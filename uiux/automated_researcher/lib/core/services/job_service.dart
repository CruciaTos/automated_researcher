import '../models/report.dart';
import '../models/research_job.dart';
import '../models/source_document.dart';
import 'api_client.dart';

class JobService {
  JobService(this._client);

  final ApiClient _client;

  Future<ResearchJob> createJob({required String topic, required int depth}) async {
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
    return JobReport.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<SourceDocument>> fetchSources(int jobId) async {
    final response = await _client.get('/jobs/$jobId/sources');
    final data = response.data as Map<String, dynamic>;
    final sources = data['sources'] as List<dynamic>? ?? [];
    return sources
        .map((item) => SourceDocument.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<String> chatWithJob(int jobId, String question) async {
    final response = await _client.post('/jobs/$jobId/chat', data: {
      'question': question,
    });
    return (response.data as Map<String, dynamic>)['answer'] as String? ?? '';
  }
}