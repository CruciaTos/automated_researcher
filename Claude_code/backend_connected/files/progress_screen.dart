import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/research_job.dart';
import '../../../core/providers/job_providers.dart';
import '../../../core/theme/desktop_theme.dart';
import '../../../core/widgets/desktop_card.dart';
import '../../../core/widgets/job_status_badge.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key, required this.jobId});

  final int jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobState = ref.watch(jobPollingProvider(jobId));

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
              context.go('/desktop/dashboard');
            }
          },
        ),
        title: const Text('Research Progress', style: Dt.cardTitle),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Dt.border),
        ),
      ),
      body: jobState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 40, color: Dt.error),
              const SizedBox(height: 12),
              Text('Failed to load job: $e', style: Dt.bodyMd),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.go('/desktop/dashboard'),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
        data: (job) => _ProgressContent(job: job),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ProgressContent extends StatelessWidget {
  const _ProgressContent({required this.job});

  final ResearchJob job;

  static const _stageOrder = [
    'queued',
    'retrieving_sources',
    'fetching_documents',
    'chunking_documents',
    'embedding_documents',
    'drafting_outline',
    'writing_report',
    'completed',
  ];

  static const _stageLabels = {
    'queued':               'Queued',
    'retrieving_sources':   'Retrieving Sources',
    'fetching_documents':   'Fetching Documents',
    'chunking_documents':   'Processing Documents',
    'embedding_documents':  'Building Knowledge Base',
    'drafting_outline':     'Drafting Outline',
    'writing_report':       'Writing Report',
    'completed':            'Completed',
  };

  @override
  Widget build(BuildContext context) {
    final isComplete = job.status == 'completed';
    final isFailed   = job.status == 'failed';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Dt.contentPadH),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.topic, style: Dt.pageTitle),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            JobStatusBadge(job.status),
                            const SizedBox(width: 12),
                            Text(
                              'Job #${job.id} · ${job.depthMinutes} min depth',
                              style: Dt.bodySm,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isComplete) ...[
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () =>
                          context.go('/jobs/${job.id}/report'),
                      icon: const Icon(Icons.description_outlined,
                          size: 15),
                      label: const Text('View Report',
                          style: TextStyle(fontSize: 13)),
                      style: FilledButton.styleFrom(
                        backgroundColor: Dt.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dt.inputRadius),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 28),

              // ── Progress bar ──────────────────────────────────────────
              if (!isFailed) ...[
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: job.progress / 100,
                          minHeight: 10,
                          backgroundColor: Dt.bgMuted,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isComplete ? Dt.success : Dt.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${job.progress}%',
                      style: Dt.cardTitle.copyWith(
                        color: isComplete ? Dt.success : Dt.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
              ],

              // ── Pipeline stages ───────────────────────────────────────
              DesktopCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pipeline', style: Dt.cardTitle),
                    const SizedBox(height: 16),
                    ..._buildStages(),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Status notice ─────────────────────────────────────────
              if (isComplete)
                DesktopCard(
                  color: Dt.successBg,
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          color: Dt.success, size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Research Complete',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Dt.success)),
                            SizedBox(height: 3),
                            Text('Your report is ready to view.',
                                style: TextStyle(
                                    fontSize: 12, color: Dt.success)),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () =>
                            context.go('/jobs/${job.id}/report'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Dt.success,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Dt.inputRadius),
                          ),
                        ),
                        child: const Text('View Report',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              if (isFailed)
                DesktopCard(
                  color: Dt.errorBg,
                  child: const Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: Dt.error, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pipeline Failed',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Dt.error)),
                            SizedBox(height: 3),
                            Text(
                                'The research pipeline encountered an error.',
                                style: TextStyle(
                                    fontSize: 12, color: Dt.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStages() {
    final currentIdx = _stageOrder.indexOf(job.status);
    return _stageOrder.map((stage) {
      final idx   = _stageOrder.indexOf(stage);
      final state = idx < currentIdx
          ? 'done'
          : idx == currentIdx
              ? 'active'
              : 'pending';
      return PipelineStageRow(
        label: _stageLabels[stage] ?? stage,
        state: state,
      );
    }).toList();
  }
}
