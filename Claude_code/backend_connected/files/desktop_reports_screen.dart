import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/research_job.dart';
import '../../../core/models/report.dart';
import '../../../core/providers/job_providers.dart';
import '../../../core/providers/report_providers.dart';
import '../../../core/providers/desktop_providers.dart';
import '../../../core/theme/desktop_theme.dart';
import '../../../core/widgets/desktop_card.dart';
import '../../../core/widgets/job_status_badge.dart';

class DesktopReportsScreen extends ConsumerWidget {
  const DesktopReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync  = ref.watch(jobListProvider);
    final selectedId = ref.watch(selectedReportIdProvider);

    return Row(
      children: [
        // ── Left: reports list ────────────────────────────────────────────
        SizedBox(
          width: 260,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Dt.border)),
              color:  Dt.bgCard,
            ),
            child: Column(
              children: [
                _ListHeader(jobsAsync: jobsAsync),
                const Divider(
                    height: 1, thickness: 1, color: Dt.border),
                Expanded(
                  child: jobsAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2)),
                    error: (e, _) => Center(
                        child:
                            Text('Error: $e', style: Dt.bodySm)),
                    data: (jobs) {
                      final completed = jobs
                          .where((j) => j.status == 'completed')
                          .toList();
                      if (completed.isEmpty) {
                        return EmptyState(
                          icon:     Icons.description_outlined,
                          title:    'No reports yet',
                          subtitle:
                              'Complete a research job to generate a report.',
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8),
                        itemCount: completed.length,
                        separatorBuilder: (_, __) =>
                            const Divider(
                                height: 1,
                                thickness: 1,
                                color: Dt.border),
                        itemBuilder: (_, i) {
                          final job      = completed[i];
                          final selected = job.id == selectedId;
                          return _ReportListTile(
                            job:        job,
                            isSelected: selected,
                            onTap: () {
                              ref
                                  .read(selectedReportIdProvider
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

        // ── Middle: report viewer ─────────────────────────────────────────
        Expanded(
          child: selectedId == null
              ? Center(
                  child: EmptyState(
                    icon:     Icons.description_outlined,
                    title:    'Select a report',
                    subtitle:
                        'Choose a completed report from the list.',
                  ),
                )
              : _ReportViewer(jobId: selectedId),
        ),

        // ── Right: outline + actions panel ────────────────────────────────
        if (selectedId != null)
          SizedBox(
            width: 240,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Dt.border)),
                color:  Dt.bgCard,
              ),
              child: _OutlinePanel(jobId: selectedId),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// List header
// ─────────────────────────────────────────────────────────────────────────────

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.jobsAsync});

  final AsyncValue<List<ResearchJob>> jobsAsync;

  @override
  Widget build(BuildContext context) {
    final count = jobsAsync.maybeWhen(
      data: (jobs) =>
          jobs.where((j) => j.status == 'completed').length,
      orElse: () => 0,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          const Text('Reports', style: Dt.pageTitle),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color:  Dt.bgMuted,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count',
                style: const TextStyle(
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                    color:      Dt.textMuted)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Report list tile
// ─────────────────────────────────────────────────────────────────────────────

class _ReportListTile extends StatefulWidget {
  const _ReportListTile({
    required this.job,
    required this.isSelected,
    required this.onTap,
  });

  final ResearchJob  job;
  final bool         isSelected;
  final VoidCallback onTap;

  @override
  State<_ReportListTile> createState() => _ReportListTileState();
}

class _ReportListTileState extends State<_ReportListTile> {
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
              Container(
                width:  30,
                height: 30,
                decoration: BoxDecoration(
                  color:  widget.isSelected
                      ? Dt.primary
                      : Dt.bgMuted,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  Icons.description_outlined,
                  size:  14,
                  color: widget.isSelected
                      ? Colors.white
                      : Dt.textMuted,
                ),
              ),
              const SizedBox(width: 10),
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
                    const SizedBox(height: 3),
                    Text(
                      '${widget.job.depthMinutes} min · Job #${widget.job.id}',
                      style: Dt.bodySm,
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
// Report viewer
// ─────────────────────────────────────────────────────────────────────────────

class _ReportViewer extends ConsumerWidget {
  const _ReportViewer({required this.jobId});

  final int jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportProvider(jobId));

    return reportAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(
          child: Text('Failed to load report: $e',
              style: Dt.bodyMd)),
      data: (report) => _ReportContent(report: report),
    );
  }
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({required this.report});

  final JobReport report;

  @override
  Widget build(BuildContext context) {
    final text =
        report.report ?? 'Report content not available.';

    return Column(
      children: [
        // Toolbar
        Container(
          height: 48,
          padding:
              const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Dt.border)),
          ),
          child: Row(
            children: [
              Text(report.topic,
                  style: Dt.cardTitle,
                  overflow: TextOverflow.ellipsis),
              const Spacer(),
              _ToolbarButton(
                icon:  Icons.copy_outlined,
                label: 'Copy',
                onTap: () =>
                    Clipboard.setData(ClipboardData(text: text)),
              ),
              const SizedBox(width: 6),
              _ToolbarButton(
                icon:  Icons.download_outlined,
                label: 'Export',
                onTap: () {/* TODO: export */},
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(40, 32, 40, 40),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(report.topic,
                      style: Dt.pageTitle
                          .copyWith(fontSize: 26)),
                  const SizedBox(height: 24),
                  Text(text,
                      style: Dt.bodyMd.copyWith(
                          fontSize: 14, height: 1.7)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Outline panel
// ─────────────────────────────────────────────────────────────────────────────

class _OutlinePanel extends ConsumerWidget {
  const _OutlinePanel({required this.jobId});

  final int jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportProvider(jobId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48,
          padding:
              const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Dt.border)),
          ),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Text('Outline', style: Dt.cardTitle),
          ),
        ),
        Expanded(
          child: reportAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2)),
            error: (_, __) => const SizedBox.shrink(),
            data: (report) {
              final sections =
                  _extractSections(report.report ?? '');
              if (sections.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No outline available.',
                      style: Dt.bodySm),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                    vertical: 8),
                itemCount: sections.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 5),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 5),
                        child: Container(
                          width:  5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Dt.primaryMid,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(sections[i],
                            style: const TextStyle(
                                fontSize: 12,
                                color:    Dt.textSecondary,
                                height:   1.4)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1, color: Dt.border),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const Text('Export', style: Dt.sectionLabel),
              const SizedBox(height: 8),
              _ExportButton(
                icon:  Icons.text_snippet_outlined,
                label: 'Copy as Text',
                onTap: () {},
              ),
              const SizedBox(height: 6),
              _ExportButton(
                icon:  Icons.code_outlined,
                label: 'Copy as Markdown',
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _extractSections(String text) {
    final lines = text.split('\n');
    return lines
        .where((l) =>
            l.trim().isNotEmpty &&
            l.trim().length > 5 &&
            l.trim().length < 80 &&
            (l.startsWith(RegExp(r'\d')) ||
                l.startsWith(RegExp(r'[A-Z]'))))
        .take(8)
        .map((l) => l.trim())
        .toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small toolbar button
// ─────────────────────────────────────────────────────────────────────────────

class _ToolbarButton extends StatefulWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData     icon;
  final String       label;
  final VoidCallback onTap;

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _hovered
                  ? Dt.bgMuted
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon,
                    size: 14, color: Dt.textSecondary),
                const SizedBox(width: 5),
                Text(widget.label,
                    style: const TextStyle(
                        fontSize: 12,
                        color:    Dt.textSecondary)),
              ],
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Export button
// ─────────────────────────────────────────────────────────────────────────────

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData     icon;
  final String       label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 34,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon:  Icon(icon, size: 13),
          label: Text(label,
              style: const TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Dt.textSecondary,
            side: const BorderSide(color: Dt.border),
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(Dt.inputRadius)),
            padding:
                const EdgeInsets.symmetric(horizontal: 10),
          ),
        ),
      );
}
