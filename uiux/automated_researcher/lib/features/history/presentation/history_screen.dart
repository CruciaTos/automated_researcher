import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/job_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsState = ref.watch(jobListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Research History')),
      body: jobsState.when(
        data: (jobs) {
          if (jobs.isEmpty) {
            return const Center(child: Text('No research jobs yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final job = jobs[index];
              return ListTile(
                title: Text(job.topic),
                subtitle: Text('Status: ${job.status} • ${job.progress}%'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/jobs/${job.id}/report'),
              );
            },
            separatorBuilder: (_, __) => const Divider(),
            itemCount: jobs.length,
          );
        },
        error: (error, _) => Center(child: Text('Failed to load jobs: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}