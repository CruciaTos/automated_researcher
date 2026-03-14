import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/job_providers.dart';
import '../../../core/theme/desktop_theme.dart';
import '../../../core/widgets/desktop_card.dart';

class DesktopNewResearchScreen extends ConsumerStatefulWidget {
  const DesktopNewResearchScreen({super.key});

  @override
  ConsumerState<DesktopNewResearchScreen> createState() =>
      _DesktopNewResearchScreenState();
}

class _DesktopNewResearchScreenState
    extends ConsumerState<DesktopNewResearchScreen> {
  final _topicCtrl = TextEditingController();
  int  _depth      = 25;
  bool _advanced   = false;

  bool _includeWikipedia = true;
  bool _includeArxiv     = true;
  bool _autoSummarize    = true;

  @override
  void dispose() {
    _topicCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creation = ref.watch(jobCreationProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: Dt.contentPadH * 2,
        vertical:   Dt.contentPadV * 1.5,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New Research Job', style: Dt.pageTitle),
              const SizedBox(height: 6),
              const Text(
                'Describe what you want researched. The AI pipeline will '
                'retrieve sources, build a knowledge base, and generate a '
                'structured report.',
                style: Dt.bodyMd,
              ),
              const SizedBox(height: 32),

              // ── Topic input ─────────────────────────────────────────
              DesktopCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width:  28,
                          height: 28,
                          decoration: BoxDecoration(
                            color:  Dt.primaryLight,
                            borderRadius:
                                BorderRadius.circular(7),
                          ),
                          child: const Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: Dt.primary),
                        ),
                        const SizedBox(width: 10),
                        const Text('Research Topic',
                            style: Dt.cardTitle),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _topicCtrl,
                      maxLines:   4,
                      minLines:   4,
                      decoration: InputDecoration(
                        hintText:
                            'e.g. "Impact of large language models on scientific research" or '
                            '"Current state of solid-state battery technology"',
                        hintStyle: const TextStyle(
                            fontSize: 13,
                            color:    Dt.textMuted,
                            height:   1.5),
                        filled:      true,
                        fillColor:   Dt.bgInput,
                        contentPadding:
                            const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  Dt.inputRadius),
                          borderSide: const BorderSide(
                              color: Dt.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  Dt.inputRadius),
                          borderSide: const BorderSide(
                              color: Dt.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  Dt.inputRadius),
                          borderSide: const BorderSide(
                              color: Dt.borderFocus,
                              width: 1.5),
                        ),
                      ),
                      style: const TextStyle(
                          fontSize: 14,
                          color:    Dt.textPrimary,
                          height:   1.5),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Be specific. More detail leads to more focused, accurate reports.',
                      style: Dt.bodySm,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Depth selector ──────────────────────────────────────
              DesktopCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width:  28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius:
                                BorderRadius.circular(7),
                          ),
                          child: const Icon(
                              Icons.timer_outlined,
                              size:  14,
                              color: Dt.info),
                        ),
                        const SizedBox(width: 10),
                        const Text('Research Depth',
                            style: Dt.cardTitle),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _DepthTile(
                          minutes:     5,
                          label:       'Quick',
                          description: '5 sources, summary outline',
                          selected:    _depth == 5,
                          onTap: () =>
                              setState(() => _depth = 5),
                        ),
                        const SizedBox(width: 12),
                        _DepthTile(
                          minutes:     25,
                          label:       'Standard',
                          description: '10 sources, full report',
                          selected:    _depth == 25,
                          onTap: () =>
                              setState(() => _depth = 25),
                        ),
                        const SizedBox(width: 12),
                        _DepthTile(
                          minutes:     40,
                          label:       'Deep',
                          description:
                              'Max sources, detailed analysis',
                          selected: _depth == 40,
                          onTap: () =>
                              setState(() => _depth = 40),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Advanced options ────────────────────────────────────
              DesktopCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => setState(
                          () => _advanced = !_advanced),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width:  28,
                              height: 28,
                              decoration: BoxDecoration(
                                color:  Dt.bgMuted,
                                borderRadius:
                                    BorderRadius.circular(7),
                              ),
                              child: const Icon(
                                  Icons.tune_outlined,
                                  size:  14,
                                  color: Dt.textSecondary),
                            ),
                            const SizedBox(width: 10),
                            const Text('Advanced Options',
                                style: Dt.cardTitle),
                            const Spacer(),
                            AnimatedRotation(
                              turns: _advanced ? 0.5 : 0,
                              duration: const Duration(
                                  milliseconds: 200),
                              child: const Icon(
                                Icons
                                    .keyboard_arrow_down_rounded,
                                size:  18,
                                color: Dt.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration:
                          const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: _advanced
                          ? _AdvancedPanel(
                              includeWikipedia:
                                  _includeWikipedia,
                              includeArxiv:  _includeArxiv,
                              autoSummarize: _autoSummarize,
                              onWikiChanged: (v) => setState(
                                  () =>
                                      _includeWikipedia = v),
                              onArxivChanged: (v) => setState(
                                  () => _includeArxiv = v),
                              onSummarizeChanged: (v) =>
                                  setState(() =>
                                      _autoSummarize = v),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Submit ──────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: creation.isLoading
                            ? null
                            : () => _submit(context),
                        icon: creation.isLoading
                            ? const SizedBox(
                                width:  16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Icon(
                                Icons.rocket_launch_outlined,
                                size: 17),
                        label: Text(
                          creation.isLoading
                              ? 'Starting research…'
                              : 'Start Research Job',
                          style: const TextStyle(
                              fontSize:   14,
                              fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Dt.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                Dt.inputRadius),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () {
                        _topicCtrl.clear();
                        setState(() {
                          _depth    = 25;
                          _advanced = false;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Dt.textSecondary,
                        side: const BorderSide(
                            color: Dt.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              Dt.inputRadius),
                        ),
                      ),
                      child: const Text('Clear'),
                    ),
                  ),
                ],
              ),
              if (creation.hasError) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Dt.errorBg,
                    borderRadius:
                        BorderRadius.circular(Dt.inputRadius),
                    border: Border.all(
                        color: Dt.error.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 16, color: Dt.error),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Failed to create job. Make sure the backend is running.',
                          style: TextStyle(
                              fontSize: 13, color: Dt.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final topic = _topicCtrl.text.trim();
    if (topic.isEmpty) return;
    await ref
        .read(jobCreationProvider.notifier)
        .createJob(topic, _depth);
    final job = ref.read(jobCreationProvider).value;
    if (job != null && mounted) {
      context.go('/jobs/${job.id}/progress');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Depth tile
// ─────────────────────────────────────────────────────────────────────────────

class _DepthTile extends StatelessWidget {
  const _DepthTile({
    required this.minutes,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final int    minutes;
  final String label;
  final String description;
  final bool   selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:  selected ? Dt.primaryLight : Dt.bgInput,
              borderRadius:
                  BorderRadius.circular(Dt.inputRadius),
              border: Border.all(
                color: selected ? Dt.primary : Dt.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Dt.primary
                        : Dt.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$minutes min',
                  style: TextStyle(
                    fontSize:    20,
                    fontWeight:  FontWeight.w800,
                    color: selected
                        ? Dt.primary
                        : Dt.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color:    selected
                        ? Dt.primary.withOpacity(0.7)
                        : Dt.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Advanced panel
// ─────────────────────────────────────────────────────────────────────────────

class _AdvancedPanel extends StatelessWidget {
  const _AdvancedPanel({
    required this.includeWikipedia,
    required this.includeArxiv,
    required this.autoSummarize,
    required this.onWikiChanged,
    required this.onArxivChanged,
    required this.onSummarizeChanged,
  });

  final bool includeWikipedia;
  final bool includeArxiv;
  final bool autoSummarize;
  final ValueChanged<bool> onWikiChanged;
  final ValueChanged<bool> onArxivChanged;
  final ValueChanged<bool> onSummarizeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          const Divider(
              height: 1, thickness: 1, color: Dt.border),
          const SizedBox(height: 14),
          _ToggleRow(
            label:    'Include Wikipedia sources',
            value:    includeWikipedia,
            onChange: onWikiChanged,
          ),
          _ToggleRow(
            label:    'Include arXiv papers',
            value:    includeArxiv,
            onChange: onArxivChanged,
          ),
          _ToggleRow(
            label:    'Auto-summarize long documents',
            value:    autoSummarize,
            onChange: onSummarizeChanged,
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChange,
  });

  final String label;
  final bool   value;
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: Dt.bodyMd)),
            Switch(
              value:     value,
              onChanged: onChange,
              activeColor: Dt.primary,
              materialTapTargetSize:
                  MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      );
}
