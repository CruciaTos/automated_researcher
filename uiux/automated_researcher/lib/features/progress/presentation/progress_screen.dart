import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/job_providers.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key, required this.jobId});

  final int jobId;

  String _statusLabel(String status) {
    switch (status) {
      case 'retrieving_sources':
        return 'Finding sources';
      case 'fetching_documents':
        return 'Analyzing documents';
      case 'drafting_report':
        return 'Writing report';
      case 'completed':
        return 'Completed';
      default:
        return 'Building knowledge base';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobState = ref.watch(jobPollingProvider(jobId));

    return Scaffold(
      appBar: AppBar(title: const Text('Research Progress')),
      body: jobState.when(
        data: (job) {
          final label = _statusLabel(job.status);
          if (job.status == 'completed') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/jobs/${job.id}/report');
            });
          }
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.topic, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: job.progress / 100),
                const SizedBox(height: 12),
                Text('$label • ${job.progress}%'),
                const SizedBox(height: 24),
                const Text('We’ll notify you once the report is ready.'),
              ],
            ),
          );
        },
        error: (error, _) => Center(
          child: Text('Failed to load progress: $error'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}