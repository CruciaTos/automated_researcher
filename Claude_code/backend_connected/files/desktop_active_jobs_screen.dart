import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/research_job.dart';
import '../../../core/providers/job_providers.dart';
import '../../../core/providers/desktop_providers.dart';
import '../../../core/theme/desktop_theme.dart';
import '../../../core/widgets/desktop_card.dart';
import '../../../core/widgets/job_status_badge.dart';

class DesktopActiveJobsScreen extends ConsumerWidget {
  const DesktopActiveJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync  = ref.watch(jobListProvider);
    final selectedId = ref.watch(selectedJobIdProvider);

    return Row(
      children: [
        // ── Left: job list ────────────────────────────────────────────────
        SizedBox(
          width: 280,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Dt.border)),
              color:  Dt.bgCard,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Row(
                    children: [
                      const Text('Jobs', style: Dt.pageTitle),
                      const Spacer(),
                      jobsAsync.when(
                        data: (jobs) =>
                            _CountBadge('${jobs.length}'),
                        loading: () => const SizedBox.shrink(),
                        error:   (_, __) =>
                            const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const Divider(
                    height: 1, thickness: 1, color: Dt.border),
                Expanded(
                  child: jobsAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2)),
                    error: (e, _) => Center(
                        child: Text('Error: $e',
                            style: Dt.bodySm)),
                    data: (jobs) {
                      if (jobs.isEmpty) {
                        return EmptyState(
                          icon:     Icons.pending_outlined,
                          title:    'No jobs yet',
                          subtitle:
                              'Start a research job to see it here.',
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8),
                        itemCount: jobs.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            thickness: 1,
                            color: Dt.border),
                        itemBuilder: (context, i) {
                          final job      = jobs[i];
                          final selected = job.id == selectedId;
                          return _JobListTile(
                            job:        job,
                            isSelected: selected,
                            onTap: () {
                              ref
                                  .read(selectedJobIdProvider
                                      .notifier)
                                  .state = job.id;
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Right: job detail ─────────────────────────────────────────────
        Expanded(
          child: selectedId == null
              ? Center(
                  child: EmptyState(
                    icon:     Icons.ads_click_outlined,
                    title:    'Select a job',
                    subtitle:
                        'Click a job from the list to see its details.',
                  ),
                )
              : _JobDetailPanel(jobId: selectedId),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Job list tile
// ─────────────────────────────────────────────────────────────────────────────

class _JobListTile extends StatefulWidget {
  const _JobListTile({
    required this.job,
    required this.isSelected,
    required this.onTap,
  });

  final ResearchJob  job;
  final bool         isSelected;
  final VoidCallback onTap;

  @override
  State<_JobListTile> createState() => _JobListTileState();
}

class _JobListTileState extends State<_JobListTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected
        ? Dt.primaryLight
        : _hovered
            ? Dt.bgMuted
            : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          color:   bg,
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (widget.isSelected)
                Container(
                  width:  3,
                  height: 36,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color:  Dt.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              else
                const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.job.topic,
                      style: Dt.cardTitle.copyWith(
                        color: widget.isSelected
                            ? Dt.primary
                            : Dt.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        JobStatusBadge(widget.job.status),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.job.progress}%',
                          style: Dt.bodySm,
                        ),
                      ],
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Job detail panel
// ─────────────────────────────────────────────────────────────────────────────

class _JobDetailPanel extends ConsumerWidget {
  const _JobDetailPanel({required this.jobId});

  final int jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobState = ref.watch(jobPollingProvider(jobId));

    return jobState.when(
      loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(
          child: Text('Failed to load job: $e',
              style: Dt.bodyMd)),
      data: (job) => _JobDetailContent(job: job),
    );
  }
}

class _JobDetailContent extends StatelessWidget {
  const _JobDetailContent({required this.job});

  final ResearchJob job;

  // All stages the backend can report (including the extended pipeline)
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dt.contentPadH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Job header ────────────────────────────────────────────────
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
              if (job.status == 'completed') ...[
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () =>
                      context.go('/jobs/${job.id}/report'),
                  icon: const Icon(
                      Icons.description_outlined, size: 15),
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
          const SizedBox(height: 24),

          // ── Progress bar ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: job.progress / 100,
                    minHeight: 8,
                    backgroundColor: Dt.bgMuted,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Dt.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${job.progress}%',
                  style: Dt.cardTitle
                      .copyWith(color: Dt.primary)),
            ],
          ),
          const SizedBox(height: 28),

          // ── Pipeline stages + details ─────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DesktopCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pipeline', style: Dt.cardTitle),
                      const SizedBox(height: 16),
                      ..._stages(job),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DesktopCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Details', style: Dt.cardTitle),
                      const SizedBox(height: 14),
                      _detailRow('Job ID',
                          '#${job.id}'),
                      _detailRow('Depth',
                          '${job.depthMinutes} minutes'),
                      _detailRow('Progress',
                          '${job.progress}%'),
                      _detailRow('Status',
                          Dt.statusLabel(job.status)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Log area ──────────────────────────────────────────────────
          DesktopCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Text('Logs', style: Dt.cardTitle),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Dt.bgMuted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('stdout',
                            style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                color: Dt.textMuted)),
                      ),
                    ],
                  ),
                ),
                const Divider(
                    height: 1, thickness: 1, color: Dt.border),
                Container(
                  width:   double.infinity,
                  height:  180,
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: Dt.bgDark,
                    borderRadius: BorderRadius.only(
                      bottomLeft:
                          Radius.circular(Dt.cardRadius),
                      bottomRight:
                          Radius.circular(Dt.cardRadius),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: _logLines(job),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _stages(ResearchJob job) {
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

  List<Widget> _logLines(ResearchJob job) {
    final lines = [
      '[${_ts()}] Job #${job.id} initialized — topic: "${job.topic}"',
      if (job.progress > 0)
        '[${_ts()}] Stage: ${Dt.statusLabel(job.status)} (${job.progress}%)',
      if (job.status == 'completed')
        '[${_ts()}] Report generation complete ✓',
      if (job.status == 'failed')
        '[${_ts()}] Pipeline failed — check backend logs.',
    ];
    return lines
        .map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(l, style: Dt.mono),
            ))
        .toList();
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(label, style: Dt.bodySm),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Dt.textPrimary)),
            ),
          ],
        ),
      );

  String _ts() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Count badge
// ─────────────────────────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  const _CountBadge(this.count);
  final String count;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color:  Dt.bgMuted,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(count,
            style: const TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color:      Dt.textMuted)),
      );
}
