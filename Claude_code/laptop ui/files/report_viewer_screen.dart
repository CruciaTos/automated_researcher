import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/report_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/citation_tile.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/skeleton_loader.dart';

class ReportViewerScreen extends ConsumerStatefulWidget {
  const ReportViewerScreen({super.key, required this.jobId});

  final int jobId;

  @override
  ConsumerState<ReportViewerScreen> createState() => _ReportViewerScreenState();
}

class _ReportViewerScreenState extends ConsumerState<ReportViewerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;
  final _scrollController = ScrollController();
  bool _showTopBar = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _scrollController.addListener(() {
      final show = _scrollController.offset > 80;
      if (show != _showTopBar) setState(() => _showTopBar = show);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider(widget.jobId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _showTopBar
            ? AppColors.surface.withOpacity(0.95)
            : AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          onPressed: () => context.go('/jobs/${widget.jobId}/report'),
          color: AppColors.primaryText,
        ),
        title: AnimatedOpacity(
          opacity: _showTopBar ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: reportState.maybeWhen(
            data: (report) => Text(
              report.topic,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
                fontFamily: 'GeneralSans',
              ),
              overflow: TextOverflow.ellipsis,
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 18),
            color: AppColors.mutedText,
            onPressed: () {},
          ),
        ],
      ),
      body: reportState.when(
        loading: () => const Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: SkeletonReport(),
        ),
        error: (error, _) => Center(
          child: Text(
            'Failed to load report: $error',
            style: const TextStyle(
              color: AppColors.error,
              fontFamily: 'GeneralSans',
            ),
          ),
        ),
        data: (report) {
          final text = report.report ?? 'Report is not available yet.';
          final citations = report.citations ?? [];

          return FadeTransition(
            opacity: _fadeIn,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          report.topic,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                            letterSpacing: -0.6,
                            height: 1.2,
                            fontFamily: 'GeneralSans',
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Divider
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 28),

                        // Report body
                        _ReportBody(text: text),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),

                // Citations section
                if (citations.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(color: AppColors.border, height: 1),
                          const SizedBox(height: 28),
                          const Text(
                            'Sources',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                              letterSpacing: -0.2,
                              fontFamily: 'GeneralSans',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${citations.length} references',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedText,
                              fontFamily: 'GeneralSans',
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final citation = citations[index];
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            0,
                            24,
                            index == citations.length - 1 ? 0 : 10,
                          ),
                          child: CitationTile(
                            index: citation.id,
                            title: citation.title,
                            url: citation.url,
                          ),
                        );
                      },
                      childCount: citations.length,
                    ),
                  ),
                ],

                // Action button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                    child: PrimaryButton(
                      label: 'Ask Follow-up Questions',
                      variant: PrimaryButtonVariant.outlined,
                      icon: Icons.chat_bubble_outline_rounded,
                      onPressed: () =>
                          context.go('/jobs/${widget.jobId}/chat'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    // Split into paragraphs and render with proper spacing
    final paragraphs = text.split('\n\n').where((p) => p.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.asMap().entries.map((entry) {
        final paragraph = entry.value.trim();
        final isHeading = paragraph.startsWith('##') || paragraph.startsWith('#');

        if (isHeading) {
          final clean = paragraph.replaceAll(RegExp(r'^#+\s*'), '');
          return Padding(
            padding: const EdgeInsets.only(top: 32, bottom: 12),
            child: Text(
              clean,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
                letterSpacing: -0.2,
                height: 1.3,
                fontFamily: 'GeneralSans',
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(
            paragraph,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.primaryText,
              height: 1.75,
              letterSpacing: 0.1,
              fontFamily: 'GeneralSans',
            ),
          ),
        );
      }).toList(),
    );
  }
}
