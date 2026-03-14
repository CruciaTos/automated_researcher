import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/report_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/skeleton_loader.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key, required this.jobId});

  final int jobId;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider(widget.jobId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: reportState.when(
          loading: () => _buildSkeleton(),
          error: (error, _) => _buildError('$error'),
          data: (report) {
            final previewText = (report.report ?? '').length > 300
                ? '${(report.report ?? '').substring(0, 300)}…'
                : (report.report ?? '');

            return FadeTransition(
              opacity: _fadeIn,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Navigation
                    GestureDetector(
                      onTap: () => context.go('/history'),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded,
                              size: 14, color: AppColors.mutedText),
                          SizedBox(width: 6),
                          Text(
                            'History',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedText,
                              fontFamily: 'GeneralSans',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Complete badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Research complete',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.success,
                              letterSpacing: 0.2,
                              fontFamily: 'GeneralSans',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

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

                    // Preview card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Preview',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.mutedText,
                              letterSpacing: 0.6,
                              fontFamily: 'GeneralSans',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            previewText.isEmpty
                                ? 'Report is still being prepared.'
                                : previewText,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.secondaryText,
                              height: 1.65,
                              fontFamily: 'GeneralSans',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Stats row
                    Row(
                      children: [
                        _StatChip(
                          icon: Icons.library_books_outlined,
                          label:
                              '${report.citations?.length ?? 0} sources',
                        ),
                        const SizedBox(width: 10),
                        _StatChip(
                          icon: Icons.article_outlined,
                          label: _wordCount(report.report ?? ''),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Actions
                    PrimaryButton(
                      label: 'Read Full Report',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () =>
                          context.go('/jobs/${widget.jobId}/report/viewer'),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Ask Follow-up Questions',
                      variant: PrimaryButtonVariant.outlined,
                      icon: Icons.chat_bubble_outline_rounded,
                      onPressed: () =>
                          context.go('/jobs/${widget.jobId}/chat'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _wordCount(String text) {
    if (text.isEmpty) return '0 words';
    final count = text.split(RegExp(r'\s+')).length;
    return '$count words';
  }

  Widget _buildSkeleton() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 48, 24, 32),
      child: SkeletonReport(),
    );
  }

  Widget _buildError(String error) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 40, color: AppColors.error),
          const SizedBox(height: 16),
          const Text(
            'Failed to load report',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
              fontFamily: 'GeneralSans',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mutedText,
              fontFamily: 'GeneralSans',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.mutedText),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.secondaryText,
              fontFamily: 'GeneralSans',
            ),
          ),
        ],
      ),
    );
  }
}
