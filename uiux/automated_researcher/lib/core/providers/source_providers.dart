import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/source_document.dart';
import '../services/job_service.dart';
import 'app_providers.dart';

final sourcesProvider = FutureProvider.family<List<SourceDocument>, int>((ref, jobId) async {
  final service = ref.watch(jobServiceProvider);
  return service.fetchSources(jobId);
});