import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report.dart';
import 'app_providers.dart';

/// Fetches the generated research report for a completed job.
///
/// Returns [JobReport] whose `report` field is non-null once the pipeline
/// has finished. If the job is not yet complete, the backend returns the
/// same shape with `report: null`.
final reportProvider =
    FutureProvider.family<JobReport, int>((ref, jobId) async {
  final client = ref.read(apiClientProvider);
  final json = await client.get('/jobs/$jobId/report');
  return JobReport.fromJson(json as Map<String, dynamic>);
});
