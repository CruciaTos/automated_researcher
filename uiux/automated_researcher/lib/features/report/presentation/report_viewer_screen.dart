import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/report_providers.dart';

class ReportViewerScreen extends ConsumerWidget {
  const ReportViewerScreen({super.key, required this.jobId});

  final int jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportState = ref.watch(reportProvider(jobId));

    return Scaffold(
      appBar: AppBar(title: const Text('Research Report')),
      body: reportState.when(
        data: (report) {
          final text = report.report ?? 'Report is not available yet.';
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(report.topic, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              Text(text, style: Theme.of(context).textTheme.bodyLarge),
            ],
          );
        },
        error: (error, _) => Center(child: Text('Failed to load report: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}