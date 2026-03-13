import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/report.dart';
import '../models/source_document.dart';
import 'app_providers.dart';

final reportProvider =
    FutureProvider.family<JobReport, int>((ref, jobId) async {
  final service = ref.watch(jobServiceProvider);
  return service.fetchReport(jobId);
});

final sourcesProvider =
    FutureProvider.family<List<SourceDocument>, int>((ref, jobId) async {
  final service = ref.watch(jobServiceProvider);
  return service.fetchSources(jobId);
});
