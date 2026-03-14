import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/report_providers.dart';
import '../../../core/theme/desktop_theme.dart';

/// Full-screen focused report viewer — navigated to via
/// `/jobs/:id/report/viewer`. Provides a distraction-free reading layout.
class ReportViewerScreen extends ConsumerWidget {
  const ReportViewerScreen({super.key, required this.jobId});

  final int jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportProvider(jobId));

    return Scaffold(
      backgroundColor: Dt.bgPage,
      appBar: AppBar(
        backgroundColor: Dt.bgSidebar,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Dt.textSecondary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/desktop/reports');
            }
          },
        ),
        title: reportAsync.hasValue
            ? Text(reportAsync.value!.topic, style: Dt.cardTitle)
            : const Text('Report', style: Dt.cardTitle),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Dt.border),
        ),
        actions: [
          if (reportAsync.hasValue)
            IconButton(
              icon: const Icon(Icons.copy_outlined,
                  color: Dt.textSecondary),
              tooltip: 'Copy report text',
              onPressed: () {
                final text = reportAsync.value?.report ?? '';
                Clipboard.setData(ClipboardData(text: text));
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: reportAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => Center(
          child: Text('Failed to load report: $e', style: Dt.bodyMd),
        ),
        data: (report) {
          final text = report.report ?? 'Report content not available.';
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(48, 40, 48, 48),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.topic,
                        style: Dt.pageTitle.copyWith(fontSize: 28)),
                    const SizedBox(height: 24),
                    const Divider(height: 1, color: Dt.border),
                    const SizedBox(height: 28),
                    Text(
                      text,
                      style: Dt.bodyMd.copyWith(
                          fontSize: 15, height: 1.8),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
