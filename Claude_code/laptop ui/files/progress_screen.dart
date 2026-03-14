import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/job_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/progress_bar.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key, required this.jobId});

  final int jobId;

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen>
    with TickerProviderStateMixin {
  late final AnimationController _dotController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeIn;

  static const _stages = [
    _StageInfo('searching_sources', 'Searching sources', Icons.travel_explore_rounded),
    _StageInfo('scraping_articles', 'Scraping articles', Icons.article_outlined),
    _StageInfo('processing_documents', 'Processing documents', Icons.description_outlined),
    _StageInfo('generating_embeddings', 'Generating embeddings', Icons.hub_outlined),
    _StageInfo('creating_outline', 'Creating research outline', Icons.format_list_bulleted_rounded),
    _StageInfo('generating_report', 'Generating report', Icons.edit_note_rounded),
    _StageInfo('finalizing_citations', 'Finalizing citations', Icons.library_books_outlined),
    _StageInfo('completed', 'Research complete', Icons.check_circle_outline_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _dotController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  _StageInfo _stageInfo(String status) {
    return _stages.firstWhere(
      (s) => s.key == status,
      orElse: () => _stages[0],
    );
  }

  int _stageIndex(String status) {
    final index = _stages.indexWhere((s) => s.key == status);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final jobState = ref.watch(jobPollingProvider(widget.jobId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: jobState.when(
          loading: () => _buildLoadingState(),
          error: (error, _) => _buildErrorState('$error'),
          data: (job) {
            if (job.status == 'completed') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.go('/jobs/${job.id}/report');
                }
              });
            }

            final info = _stageInfo(job.status);
            final currentIndex = _stageIndex(job.status);
            final progress = job.progress / 100.0;

            return FadeTransition(
              opacity: _fadeIn,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back / cancel
                    GestureDetector(
                      onTap: () => context.go('/dashboard'),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded,
                              size: 14, color: AppColors.mutedText),
                          SizedBox(width: 6),
                          Text(
                            'Back',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedText,
                              fontFamily: 'GeneralSans',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Topic
                    Text(
                      job.topic,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                        letterSpacing: -0.4,
                        height: 1.25,
                        fontFamily: 'GeneralSans',
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 40),

                    // Progress bar
                    ResearchProgressBar(
                      progress: progress,
                      height: 3,
                      showPulse: job.status != 'completed',
                    ),
                    const SizedBox(height: 16),

                    // Progress percent + stage
                    Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            '${job.progress}%',
                            key: ValueKey(job.progress),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                              fontFamily: 'GeneralSans',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '·',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontFamily: 'GeneralSans',
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            info.label,
                            key: ValueKey(info.key),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.secondaryText,
                              fontFamily: 'GeneralSans',
                            ),
                          ),
                        ),
                        if (job.status != 'completed') ...[
                          const SizedBox(width: 4),
                          _AnimatedDots(controller: _dotController),
                        ],
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Stage pipeline
                    const Text(
                      'Pipeline',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.mutedText,
                        letterSpacing: 0.6,
                        fontFamily: 'GeneralSans',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _stages.length,
                        itemBuilder: (context, index) {
                          final stage = _stages[index];
                          final isDone = index < currentIndex ||
                              job.status == 'completed';
                          final isCurrent =
                              index == currentIndex &&
                                  job.status != 'completed';

                          return _StageRow(
                            stage: stage,
                            isDone: isDone,
                            isCurrent: isCurrent,
                            isLast: index == _stages.length - 1,
                            dotController: _dotController,
                          );
                        },
                      ),
                    ),

                    // Footer note
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 14, color: AppColors.mutedText),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You can leave this screen. We\'ll notify you when your report is ready.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedText,
                                height: 1.4,
                                fontFamily: 'GeneralSans',
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildLoadingState() {
    return const Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryText),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 40, color: AppColors.error),
          const SizedBox(height: 16),
          const Text(
            'Failed to track progress',
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

class _StageInfo {
  const _StageInfo(this.key, this.label, this.icon);
  final String key;
  final String label;
  final IconData icon;
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.stage,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
    required this.dotController,
  });

  final _StageInfo stage;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;
  final AnimationController dotController;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.primaryText
                        : isCurrent
                            ? AppColors.border
                            : AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone
                          ? AppColors.primaryText
                          : isCurrent
                              ? AppColors.borderBright
                              : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isDone ? Icons.check_rounded : stage.icon,
                    size: 12,
                    color: isDone
                        ? AppColors.background
                        : isCurrent
                            ? AppColors.primaryText
                            : AppColors.mutedText,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isDone ? AppColors.borderBright : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 4),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isCurrent ? FontWeight.w500 : FontWeight.w400,
                  color: isDone
                      ? AppColors.secondaryText
                      : isCurrent
                          ? AppColors.primaryText
                          : AppColors.mutedText,
                  fontFamily: 'GeneralSans',
                ),
                child: Text(stage.label),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDots extends StatelessWidget {
  const _AnimatedDots({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final opacity = controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final dotOpacity = ((opacity + i * 0.3) % 1.0).clamp(0.2, 1.0);
            return Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Opacity(
                opacity: dotOpacity,
                child: Container(
                  width: 3,
                  height: 3,
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryText,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
