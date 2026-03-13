import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/research_job.dart';
import '../../../core/providers/job_providers.dart';
import '../../../core/theme/desktop_theme.dart';
import '../../../core/widgets/desktop_card.dart';
import '../../../core/widgets/job_status_badge.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/stat_card.dart';

class DesktopDashboardScreen extends ConsumerStatefulWidget {
  const DesktopDashboardScreen({super.key});

  @override
  ConsumerState<DesktopDashboardScreen> createState() =>
      _DesktopDashboardScreenState();
}

class _DesktopDashboardScreenState
    extends ConsumerState<DesktopDashboardScreen> {
  final _topicCtrl = TextEditingController();
  int _selectedDepth = 25;

  @override
  void dispose() {
    _topicCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(jobListProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Main area (2/3 width) ─────────────────────────────────────────
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Dt.contentPadH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _greeting(),
                const SizedBox(height: 24),
                _statsRow(jobsAsync),
                const SizedBox(height: 28),
                _recentJobsSection(jobsAsync),
              ],
            ),
          ),
        ),

        // ── Right panel: Quick start ──────────────────────────────────────
        SizedBox(
          width: 300,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Dt.border)),
              color: Dt.bgCard,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Start', style: Dt.pageTitle),
                const SizedBox(height: 6),
                const Text(
                  'Launch a new research job in seconds.',
                  style: Dt.bodyMd,
                ),
                const SizedBox(height: 24),
                _quickStartForm(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Greeting ─────────────────────────────────────────────────────────────

  Widget _greeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$greeting 👋', style: Dt.pageTitle.copyWith(fontSize: 24)),
        const SizedBox(height: 4),
        const Text(
          'Your research workspace is ready.',
          style: Dt.bodyMd,
        ),
      ],
    );
  }

  // ─── Stats row ────────────────────────────────────────────────────────────

  Widget _statsRow(AsyncValue<List<ResearchJob>> jobsAsync) {
    return jobsAsync.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (jobs) {
        final active    = jobs.where((j) =>
            j.status != 'completed' && j.status != 'failed').length;
        final completed = jobs.where((j) => j.status == 'completed').length;

        return LayoutBuilder(builder: (context, constraints) {
          return Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Total Jobs',
                  value: '${jobs.length}',
                  icon:  Icons.work_outline_rounded,
                  accentColor: Dt.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: StatCard(
                  label: 'Active Jobs',
                  value: '$active',
                  icon:  Icons.pending_outlined,
                  accentColor: Dt.info,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: StatCard(
                  label: 'Reports Ready',
                  value: '$completed',
                  icon:  Icons.description_outlined,
                  accentColor: Dt.success,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: StatCard(
                  label: 'Sources Indexed',
                  value: '—',
                  icon:  Icons.auto_stories_outlined,
                  accentColor: Dt.warning,
                ),
              ),
            ],
          );
        });
      },
    );
  }

  // ─── Recent jobs ──────────────────────────────────────────────────────────

  Widget _recentJobsSection(AsyncValue<List<ResearchJob>> jobsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Recent Jobs',
          trailing: TextButton.icon(
            onPressed: () => context.go('/desktop/jobs'),
            icon: const Icon(Icons.arrow_forward_rounded, size: 14),
            label: const Text('View all', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(height: 12),
        jobsAsync.when(
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => Text('Failed to load jobs: $e', style: Dt.bodySm),
          data: (jobs) {
            if (jobs.isEmpty) {
              return EmptyState(
                icon:     Icons.inbox_outlined,
                title:    'No research jobs yet',
                subtitle: 'Start your first job using the quick-start panel.',
              );
            }
            final recent = jobs.take(8).toList();
            return DesktopCard(
              padding: EdgeInsets.zero,
              child: _JobTable(jobs: recent),
            );
          },
        ),
      ],
    );
  }

  // ─── Quick-start form ─────────────────────────────────────────────────────

  Widget _quickStartForm(BuildContext context) {
    final creation = ref.watch(jobCreationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Research topic', style: Dt.bodyMd),
        const SizedBox(height: 6),
        TextField(
          controller: _topicCtrl,
          maxLines: 3,
          minLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g. Quantum computing breakthroughs 2025',
            hintStyle: const TextStyle(fontSize: 13, color: Dt.textMuted),
            filled: true,
            fillColor: Dt.bgInput,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dt.inputRadius),
              borderSide: const BorderSide(color: Dt.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dt.inputRadius),
              borderSide: const BorderSide(color: Dt.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dt.inputRadius),
              borderSide: const BorderSide(color: Dt.borderFocus, width: 1.5),
            ),
          ),
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 16),
        const Text('Research depth', style: Dt.bodyMd),
        const SizedBox(height: 8),
        Row(
          children: [5, 25, 40].map((depth) {
            final selected = _selectedDepth == depth;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDepth = depth),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color:  selected ? Dt.primary : Dt.bgInput,
                      borderRadius: BorderRadius.circular(Dt.inputRadius),
                      border: Border.all(
                        color: selected ? Dt.primary : Dt.border,
                      ),
                    ),
                    child: Text(
                      '$depth min',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : Dt.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: ElevatedButton.icon(
            onPressed: creation.isLoading
                ? null
                : () async {
                    final topic = _topicCtrl.text.trim();
                    if (topic.isEmpty) return;
                    await ref
                        .read(jobCreationProvider.notifier)
                        .createJob(topic, _selectedDepth);
                    final job = ref.read(jobCreationProvider).value;
                    if (job != null && mounted) {
                      _topicCtrl.clear();
                      context.go('/jobs/${job.id}/progress');
                    }
                  },
            icon: creation.isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.rocket_launch_outlined, size: 16),
            label: Text(creation.isLoading ? 'Starting…' : 'Start Research',
                style: const TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Dt.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dt.inputRadius),
              ),
            ),
          ),
        ),
        if (creation.hasError) ...[
          const SizedBox(height: 10),
          Text(
            'Failed to start job. Is the backend running?',
            style: Dt.bodySm.copyWith(color: Dt.error),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Job table
// ─────────────────────────────────────────────────────────────────────────────

class _JobTable extends StatelessWidget {
  const _JobTable({required this.jobs});

  final List<ResearchJob> jobs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: const [
              SizedBox(width: 32),
              Expanded(flex: 4, child: Text('TOPIC',    style: Dt.sectionLabel)),
              Expanded(flex: 2, child: Text('STATUS',   style: Dt.sectionLabel)),
              Expanded(flex: 2, child: Text('PROGRESS', style: Dt.sectionLabel)),
              Expanded(flex: 2, child: Text('STARTED',  style: Dt.sectionLabel)),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Dt.border),
        // Rows
        ...jobs.asMap().entries.map((e) => _JobRow(job: e.value, index: e.key)),
      ],
    );
  }
}

class _JobRow extends StatefulWidget {
  const _JobRow({required this.job, required this.index});

  final ResearchJob job;
  final int         index;

  @override
  State<_JobRow> createState() => _JobRowState();
}

class _JobRowState extends State<_JobRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final created = _formatDate(job.createdAt);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(
          job.status == 'completed'
              ? '/desktop/reports'
              : '/desktop/jobs',
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          color: _hovered ? Dt.bgMuted : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '${widget.index + 1}',
                  style: Dt.bodySm,
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  job.topic,
                  style: Dt.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(flex: 2, child: JobStatusBadge(job.status)),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: job.progress / 100,
                          minHeight: 5,
                          backgroundColor: Dt.bgMuted,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Dt.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${job.progress}%', style: Dt.bodySm),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(created, style: Dt.bodySm),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inHours   < 1)  return '${diff.inMinutes}m ago';
    if (diff.inDays    < 1)  return '${diff.inHours}h ago';
    if (diff.inDays    < 7)  return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
