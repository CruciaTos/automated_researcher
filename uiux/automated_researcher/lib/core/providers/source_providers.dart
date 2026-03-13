import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/source_document.dart';
import 'app_providers.dart';

final sourcesProvider = FutureProvider.family<List<SourceDocument>, String>((ref, jobId) async {
  final service = ref.watch(jobServiceProvider);
  return service.fetchSources(jobId);
});