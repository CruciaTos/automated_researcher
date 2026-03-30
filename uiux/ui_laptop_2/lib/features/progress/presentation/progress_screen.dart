import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/api_error.dart';
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
  late final AnimationController _dotCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeIn;
  bool _didNavigateToReport = false;

  // Matches backend pipeline stages in research_pipeline.py exactly
  static const _stages = [
    _Stage('queued', 'Queued', Icons.hourglass_empty_rounded),
    _Stage('retrieving_sources', 'Searching sources', Icons.travel_explore_rounded),
    _Stage('fetching_documents', 'Fetching documents', Icons.article_outlined),
    _Stage('chunking_documents', 'Processing documents', Icons.description_outlined),
    _Stage('embedding_documents', 'Generating embeddings', Icons.hub_outlined),
    _Stage('drafting_outline', 'Creating outline', Icons.format_list_bulleted_rounded),
    _Stage('writing_report', 'Writing report', Icons.edit_note_rounded),
    _Stage('completed', 'Research complete', Icons.check_circle_outline_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _dotCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeIn =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _dotCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  _Stage _stageFor(String status) => _stages.firstWhere(
      (s) => s.key == status,
      orElse: () => _stages[0]);

  int _indexFor(String status) {
    final i = _stages.indexWhere((s) => s.key == status);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobPollingProvider(widget.jobId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: state.when(
          loading: () => const Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryText))),
          ),
          error: (e, _) => _errorView('$e'),
          data: (job) {
            if (job.status == 'completed' && !_didNavigateToReport) {
              _didNavigateToReport = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) context.go('/jobs/${job.id}/report');
              });
            }

            if (job.status == 'failed') {
              return _failedView();
            }

            final stage = _stageFor(job.status);
            final idx = _indexFor(job.status);
            final progress = job.progress / 100.0;

            return FadeTransition(
              opacity: _fadeIn,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back
                    GestureDetector(
                      onTap: () => context.go('/dashboard'),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded,
                              size: 14, color: AppColors.mutedText),
                          SizedBox(width: 6),
                          Text('Back',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.mutedText,
                                  fontFamily: 'GeneralSans')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Topic
                    Text(job.topic,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                            letterSpacing: -0.4,
                            height: 1.25,
                            fontFamily: 'GeneralSans'),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 40),

                    // Progress bar
                    ResearchProgressBar(
                        progress: progress,
                        height: 3,
                        showPulse: job.status != 'completed'),
                    const SizedBox(height: 16),

                    // Status row
                    Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text('${job.progress}%',
                              key: ValueKey(job.progress),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText,
                                  fontFamily: 'GeneralSans')),
                        ),
                        const SizedBox(width: 8),
                        const Text('·',
                            style: TextStyle(
                                color: AppColors.mutedText,
                                fontFamily: 'GeneralSans')),
                        const SizedBox(width: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(stage.label,
                              key: ValueKey(stage.key),
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.secondaryText,
                                  fontFamily: 'GeneralSans')),
                        ),
                        if (job.status != 'completed') ...[
                          const SizedBox(width: 4),
                          _AnimatedDots(ctrl: _dotCtrl),
                        ],
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Pipeline label
                    const Text('PIPELINE',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.mutedText,
                            letterSpacing: 0.6,
                            fontFamily: 'GeneralSans')),
                    const SizedBox(height: 16),

                    // Stage list
                    Expanded(
                      child: ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _stages.length,
                        itemBuilder: (_, i) {
                          final s = _stages[i];
                          final done = i < idx || job.status == 'completed';
                          final current =
                              i == idx && job.status != 'completed';
                          return _StageRow(
                              stage: s,
                              isDone: done,
                              isCurrent: current,
                              isLast: i == _stages.length - 1,
                              dotCtrl: _dotCtrl);
                        },
                      ),
                    ),

                    // Footer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.border, width: 1)),
                      child: const Row(children: [
                        Icon(Icons.info_outline_rounded,
                            size: 14, color: AppColors.mutedText),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                              "You can leave this screen. We'll notify you when your report is ready.",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mutedText,
                                  height: 1.4,
                                  fontFamily: 'GeneralSans')),
                        ),
                      ]),
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

  Widget _errorView(String msg) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline_rounded,
              size: 40, color: AppColors.error),
          const SizedBox(height: 16),
          const Text('Failed to track progress',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                  fontFamily: 'GeneralSans')),
          const SizedBox(height: 8),
          Text(msg,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText,
                  fontFamily: 'GeneralSans'),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => ref
                .read(jobPollingProvider(widget.jobId).notifier)
                .refreshNow(),
            child: const Text('Retry'),
          ),
        ]),
      );

  Widget _failedView() {
    final state = ref.watch(jobPollingProvider(widget.jobId));
    String detail = 'The research job failed. Please retry.';

    state.whenOrNull(
      error: (error, _) {
        if (error is ApiError) {
          detail = error.detail;
          return;
        }
        detail = error.toString();
      },
    );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          const Text(
            'Research failed',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
              fontFamily: 'GeneralSans',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mutedText,
              fontFamily: 'GeneralSans',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => ref
                .read(jobPollingProvider(widget.jobId).notifier)
                .refreshNow(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _Stage {
  const _Stage(this.key, this.label, this.icon);
  final String key;
  final String label;
  final IconData icon;
}

class _StageRow extends StatelessWidget {
  const _StageRow(
      {required this.stage,
      required this.isDone,
      required this.isCurrent,
      required this.isLast,
      required this.dotCtrl});

  final _Stage stage;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;
  final AnimationController dotCtrl;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 32,
          child: Column(children: [
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
          ]),
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
      ]),
    );
  }
}

class _AnimatedDots extends StatelessWidget {
  const _AnimatedDots({required this.ctrl});
  final AnimationController ctrl;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final op = ((ctrl.value + i * 0.3) % 1.0).clamp(0.2, 1.0);
          return Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Opacity(
              opacity: op,
              child: Container(
                width: 3,
                height: 3,
                decoration: const BoxDecoration(
                    color: AppColors.secondaryText, shape: BoxShape.circle),
              ),
            ),
          );
        }),
      ),
    );
  }
}
