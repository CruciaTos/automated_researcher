import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/job_providers.dart';
import '../../../core/providers/source_providers.dart';

class SourcesScreen extends ConsumerWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsState = ref.watch(jobListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sources')),
      body: jobsState.when(
        data: (jobs) {
          if (jobs.isEmpty) {
            return const Center(child: Text('No jobs yet.'));
          }
          final latestJob = jobs.first;
          final sourcesState = ref.watch(sourcesProvider(latestJob.id as int));
          return sourcesState.when(
            data: (sources) {
              if (sources.isEmpty) {
                return const Center(child: Text('No sources available.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final source = sources[index];
                  return ListTile(
                    title: Text(source.title),
                    subtitle: Text(source.snippet),
                    trailing: Text(source.sourceType),
                  );
                },
                separatorBuilder: (_, __) => const Divider(),
                itemCount: sources.length,
              );
            },
            error: (error, _) => Center(child: Text('Failed to load sources: $error')),
            loading: () => const Center(child: CircularProgressIndicator()),
          );
        },
        error: (error, _) => Center(child: Text('Failed to load jobs: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}