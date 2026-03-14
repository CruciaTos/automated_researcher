import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/report.dart';
import '../../../core/providers/report_providers.dart';
import '../../../core/theme/desktop_theme.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key, required this.jobId});

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
          icon: const Icon(Icons.arrow_back_rounded,
              color: Dt.textSecondary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/desktop/reports');
            }
          },
        ),
        title: const Text('Research Report', style: Dt.cardTitle),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Dt.border),
        ),
        actions: [
          if (reportAsync.hasValue) ...[
            TextButton.icon(
              onPressed: () => context.go('/jobs/$jobId/chat'),
              icon: const Icon(Icons.chat_outlined,
                  size: 15, color: Dt.textSecondary),
              label: const Text('Chat with AI',
                  style: TextStyle(fontSize: 13, color: Dt.textSecondary)),
            ),
            TextButton.icon(
              onPressed: () {
                final text =
                    reportAsync.value?.report ?? '';
                Clipboard.setData(ClipboardData(text: text));
              },
              icon: const Icon(Icons.copy_outlined,
                  size: 15, color: Dt.textSecondary),
              label: const Text('Copy',
                  style: TextStyle(fontSize: 13, color: Dt.textSecondary)),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: reportAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 40, color: Dt.error),
              const SizedBox(height: 12),
              Text('Failed to load report: $e', style: Dt.bodyMd),
            ],
          ),
        ),
        data: (report) => _ReportBody(report: report),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});

  final JobReport report;

  @override
  Widget build(BuildContext context) {
    final text = report.report ?? 'Report content not yet available.';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: Dt.contentPadH, vertical: Dt.contentPadV),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(report.topic,
                  style: Dt.pageTitle.copyWith(fontSize: 26)),
              const SizedBox(height: 20),
              const Divider(height: 1, color: Dt.border),
              const SizedBox(height: 28),
              Text(
                text,
                style: Dt.bodyMd.copyWith(fontSize: 14, height: 1.75),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
