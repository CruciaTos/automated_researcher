import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/report_providers.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key, required this.jobId});

  final int jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportState = ref.watch(reportProvider(jobId));

    return Scaffold(
      appBar: AppBar(title: const Text('Report Ready')),
      body: reportState.when(
        data: (report) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.topic, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                Text(
                  report.report ?? 'Report is still being prepared.',
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/jobs/$jobId/report/viewer'),
                  child: const Text('Open Full Report'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go('/jobs/$jobId/chat'),
                  child: const Text('Ask Follow-up Questions'),
                ),
              ],
            ),
          );
        },
        error: (error, _) => Center(child: Text('Failed to load report: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}