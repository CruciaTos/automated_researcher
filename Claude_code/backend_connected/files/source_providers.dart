import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/source_document.dart';
import 'app_providers.dart';

/// Returns the list of source documents retrieved for a given job.
///
/// Response shape: `{ "job_id": ..., "topic": ..., "sources": [ {...} ] }`
final sourcesProvider =
    FutureProvider.family<List<SourceDocument>, int>((ref, jobId) async {
  final client = ref.read(apiClientProvider);
  final json =
      await client.get('/jobs/$jobId/sources') as Map<String, dynamic>;
  final sources = json['sources'] as List<dynamic>? ?? <dynamic>[];
  return sources
      .map((s) => SourceDocument.fromJson(s as Map<String, dynamic>))
      .toList();
});
