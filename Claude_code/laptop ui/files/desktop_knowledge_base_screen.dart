import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/research_job.dart';
import '../../../core/models/source_document.dart';
import '../../../core/providers/job_providers.dart';
import '../../../core/providers/source_providers.dart';
import '../../../core/theme/desktop_theme.dart';
import '../../../core/widgets/desktop_card.dart';

// ─── Local state providers ────────────────────────────────────────────────────

final _kbSearchProvider     = StateProvider<String>((ref) => '');
final _kbSelectedSrcProvider = StateProvider<SourceDocument?>((ref) => null);
final _kbSelectedJobProvider = StateProvider<int?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────

class DesktopKnowledgeBaseScreen extends ConsumerWidget {
  const DesktopKnowledgeBaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync  = ref.watch(jobListProvider);
    final selectedId = ref.watch(_kbSelectedSrcProvider);

    return Row(
      children: [
        // ── Left panel: job selector + source list ────────────────────────
        SizedBox(
          width: 300,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Dt.border)),
              color: Dt.bgCard,
            ),
            child: Column(
              children: [
                _KbHeader(jobsAsync: jobsAsync),
                const Divider(height: 1, color: Dt.border),
                Expanded(child: _SourceList(jobsAsync: jobsAsync)),
              ],
            ),
          ),
        ),

        // ── Right: source preview ─────────────────────────────────────────
        Expanded(
          child: selectedId == null
              ? Center(
                  child: EmptyState(
                    icon:     Icons.menu_book_outlined,
                    title:    'Select a source',
                    subtitle: 'Click on a document to preview its content.',
                  ),
                )
              : _SourcePreview(doc: selectedId),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KB header — job selector + search
// ─────────────────────────────────────────────────────────────────────────────

class _KbHeader extends ConsumerWidget {
  const _KbHeader({required this.jobsAsync});

  final AsyncValue<List<ResearchJob>> jobsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedJobId = ref.watch(_kbSelectedJobProvider);
    final query         = ref.watch(_kbSearchProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Knowledge Base', style: Dt.pageTitle),
          const SizedBox(height: 10),

          // Job selector
          jobsAsync.maybeWhen(
            data: (jobs) => jobs.isEmpty
                ? const SizedBox.shrink()
                : Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Dt.bgInput,
                      borderRadius: BorderRadius.circular(Dt.inputRadius),
                      border: Border.all(color: Dt.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: selectedJobId,
                        isExpanded: true,
                        hint: const Text('Select job',
                            style: TextStyle(fontSize: 13, color: Dt.textMuted)),
                        style: const TextStyle(
                            fontSize: 13, color: Dt.textPrimary),
                        icon: const Icon(Icons.expand_more_rounded,
                            size: 16, color: Dt.textMuted),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('All jobs'),
                          ),
                          ...jobs.map((j) => DropdownMenuItem<int?>(
                                value: j.id,
                                child: Text(
                                  j.topic,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              )),
                        ],
                        onChanged: (v) {
                          ref.read(_kbSelectedJobProvider.notifier).state = v;
                          ref.read(_kbSelectedSrcProvider.notifier).state = null;
                        },
                      ),
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),

          // Search
          SizedBox(
            height: 34,
            child: TextField(
              onChanged: (v) =>
                  ref.read(_kbSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText:  'Search sources…',
                hintStyle: const TextStyle(fontSize: 13, color: Dt.textMuted),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 16, color: Dt.textMuted),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                isDense: true,
                filled: true,
                fillColor: Dt.bgInput,
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
                  borderSide:
                      const BorderSide(color: Dt.borderFocus, width: 1.5),
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Source list
// ─────────────────────────────────────────────────────────────────────────────

class _SourceList extends ConsumerWidget {
  const _SourceList({required this.jobsAsync});

  final AsyncValue<List<ResearchJob>> jobsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedJobId = ref.watch(_kbSelectedJobProvider);
    final query         = ref.watch(_kbSearchProvider).toLowerCase();

    return jobsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) =>
          Center(child: Text('Error: $e', style: Dt.bodySm)),
      data: (jobs) {
        if (jobs.isEmpty) {
          return EmptyState(
            icon:  Icons.auto_stories_outlined,
            title: 'No sources indexed',
          );
        }

        // Use first job if none selected
        final jobId = selectedJobId ?? jobs.first.id;
        final sourcesAsync = ref.watch(sourcesProvider(jobId));

        return sourcesAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (e, _) =>
              Center(child: Text('Failed to load sources', style: Dt.bodySm)),
          data: (sources) {
            final filtered = query.isEmpty
                ? sources
                : sources
                    .where((s) =>
                        s.title.toLowerCase().contains(query) ||
                        s.snippet.toLowerCase().contains(query))
                    .toList();

            if (filtered.isEmpty) {
              return EmptyState(
                icon:  Icons.search_off_outlined,
                title: 'No matching sources',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Dt.border),
              itemBuilder: (_, i) {
                final src      = filtered[i];
                final selected =
                    ref.watch(_kbSelectedSrcProvider)?.title == src.title;
                return _SourceTile(
                  source:     src,
                  isSelected: selected,
                  onTap: () =>
                      ref.read(_kbSelectedSrcProvider.notifier).state = src,
                );
              },
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Source tile
// ─────────────────────────────────────────────────────────────────────────────

class _SourceTile extends StatefulWidget {
  const _SourceTile({
    required this.source,
    required this.isSelected,
    required this.onTap,
  });

  final SourceDocument source;
  final bool           isSelected;
  final VoidCallback   onTap;

  @override
  State<_SourceTile> createState() => _SourceTileState();
}

class _SourceTileState extends State<_SourceTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected
        ? Dt.primaryLight
        : _hovered
            ? Dt.bgMuted
            : Colors.transparent;

    final srcColor = _sourceColor(widget.source.sourceType);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: srcColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    widget.source.sourceType.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: srcColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.source.title,
                      style: Dt.cardTitle.copyWith(
                        color: widget.isSelected ? Dt.primary : Dt.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.source.snippet,
                      style: Dt.bodySm,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Color _sourceColor(String type) {
    switch (type.toLowerCase()) {
      case 'wikipedia':  return Dt.info;
      case 'arxiv':      return Dt.success;
      default:           return Dt.warning;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Source preview
// ─────────────────────────────────────────────────────────────────────────────

class _SourcePreview extends StatelessWidget {
  const _SourcePreview({required this.doc});

  final SourceDocument doc;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Dt.border)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Dt.bgMuted,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  doc.sourceType.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Dt.textMuted,
                      letterSpacing: 0.8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  doc.title,
                  style: Dt.cardTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (doc.url.isNotEmpty)
                TextButton.icon(
                  onPressed: () {/* TODO: open URL */},
                  icon:  const Icon(Icons.open_in_new_rounded, size: 13),
                  label: const Text('Open source',
                      style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.title,
                      style: Dt.pageTitle.copyWith(fontSize: 22)),
                  if (doc.url.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(doc.url,
                        style: Dt.bodySm.copyWith(color: Dt.info),
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Dt.border),
                  const SizedBox(height: 20),
                  Text(doc.snippet,
                      style: Dt.bodyMd.copyWith(fontSize: 14, height: 1.7)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
