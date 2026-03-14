import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/research_job.dart';
import 'app_providers.dart';

// ─── Job list ─────────────────────────────────────────────────────────────────

/// Fetches the full list of research jobs from `GET /jobs`.
///
/// Invalidate this provider after creating a job so the list refreshes:
/// ```dart
/// ref.invalidate(jobListProvider);
/// ```
final jobListProvider = FutureProvider<List<ResearchJob>>((ref) async {
  final client = ref.read(apiClientProvider);
  final json = await client.get('/jobs') as List<dynamic>;
  return json
      .map((j) => ResearchJob.fromJson(j as Map<String, dynamic>))
      .toList();
});

// ─── Job polling ──────────────────────────────────────────────────────────────

/// Polls `GET /jobs/{jobId}` every 3 seconds.
///
/// The stream emits on every poll and **stops automatically** once the job
/// reaches a terminal state (`completed` or `failed`), conserving resources.
final jobPollingProvider =
    StreamProvider.family<ResearchJob, int>((ref, jobId) async* {
  while (true) {
    try {
      final client = ref.read(apiClientProvider);
      final json = await client.get('/jobs/$jobId');
      final job = ResearchJob.fromJson(json as Map<String, dynamic>);
      yield job;
      if (job.status == 'completed' || job.status == 'failed') return;
    } catch (e) {
      // Surface the error and stop polling so the UI can show it.
      rethrow;
    }
    await Future.delayed(const Duration(seconds: 3));
  }
});

// ─── Job creation ─────────────────────────────────────────────────────────────

/// Holds the state of an in-flight job creation request.
///
/// Initial state: `AsyncData(null)` — no job created yet.
/// During creation: `AsyncLoading()` — button is disabled.
/// On success: `AsyncData(ResearchJob)` — navigate to /progress.
/// On failure: `AsyncError(...)` — error banner shown in UI.
class JobCreationNotifier extends AsyncNotifier<ResearchJob?> {
  @override
  Future<ResearchJob?> build() => Future.value(null);

  /// Calls `POST /jobs` and stores the created [ResearchJob].
  /// Also invalidates [jobListProvider] so the list reflects the new job.
  Future<void> createJob(String topic, int depthMinutes) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(apiClientProvider);
      final json = await client.post(
        '/jobs',
        body: {
          'topic': topic,
          'depth_minutes': depthMinutes,
        },
      );
      final job = ResearchJob.fromJson(json as Map<String, dynamic>);
      // Refresh the dashboard job list immediately after creation.
      ref.invalidate(jobListProvider);
      return job;
    });
  }
}

final jobCreationProvider =
    AsyncNotifierProvider<JobCreationNotifier, ResearchJob?>(
  JobCreationNotifier.new,
);
