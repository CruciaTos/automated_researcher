import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/research_job.dart';
import '../services/job_service.dart';
import 'app_providers.dart';

final jobListProvider = FutureProvider<List<ResearchJob>>((ref) async {
  final service = ref.watch(jobServiceProvider);
  return service.fetchJobs();
});

final jobDetailProvider = FutureProvider.family<ResearchJob, int>((ref, jobId) async {
  final service = ref.watch(jobServiceProvider);
  return service.fetchJob(jobId);
});

class JobCreationController extends StateNotifier<AsyncValue<ResearchJob?>> {
  JobCreationController(this._service) : super(const AsyncValue.data(null));

  final JobService _service;

  Future<void> createJob(String topic, int depth) async {
    state = const AsyncValue.loading();
    try {
      final job = await _service.createJob(topic: topic, depth: depth);
      state = AsyncValue.data(job);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final jobCreationProvider = StateNotifierProvider<JobCreationController, AsyncValue<ResearchJob?>>((ref) {
  return JobCreationController(ref.watch(jobServiceProvider));
});

class JobPollingController extends StateNotifier<AsyncValue<ResearchJob>> {
  JobPollingController(this._service, this.jobId) : super(const AsyncValue.loading()) {
    _startPolling();
  }

  final JobService _service;
  final int jobId;
  Timer? _timer;

  void _startPolling() {
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _fetch());
  }

  Future<void> _fetch() async {
    try {
      final job = await _service.fetchJob(jobId);
      state = AsyncValue.data(job);
      if (job.status == 'completed') {
        _timer?.cancel();
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final jobPollingProvider = StateNotifierProvider.family<JobPollingController, AsyncValue<ResearchJob>, int>((ref, jobId) {
  return JobPollingController(ref.watch(jobServiceProvider), jobId);
});