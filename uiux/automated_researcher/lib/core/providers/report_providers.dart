import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/report.dart';
import 'app_providers.dart';

final reportProvider = FutureProvider.family<JobReport, int>((ref, jobId) async {
  final service = ref.watch(jobServiceProvider);
  return service.fetchReport(jobId);
});