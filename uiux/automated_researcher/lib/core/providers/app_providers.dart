import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import '../services/job_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final jobServiceProvider = Provider<JobService>((ref) {
  final client = ref.watch(apiClientProvider);
  return JobService(client);
});