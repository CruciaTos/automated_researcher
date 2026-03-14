import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/job_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/research_card.dart';
import '../../../core/widgets/skeleton_loader.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(jobListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'History',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                        letterSpacing: -0.8,
                        height: 1.1,
                        fontFamily: 'GeneralSans',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your past research jobs',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondaryText,
                        fontFamily: 'GeneralSans',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Content
              Expanded(
                child: jobsState.when(
                  loading: () => _buildSkeleton(),
                  error: (error, _) => _buildError('$error'),
                  data: (jobs) {
                    if (jobs.isEmpty) return _buildEmpty();

                    return RefreshIndicator(
                      onRefresh: () => ref.refresh(jobListProvider.future),
                      color: AppColors.primaryText,
                      backgroundColor: AppColors.surface,
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(24, 0, 24, 32),
                        itemCount: jobs.length,
                        itemBuilder: (context, index) {
                          final job = jobs[index];
                          final date = _formatDate(
                            DateTime.tryParse(job.createdAt ?? '') ??
                                DateTime.now(),
                          );

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ResearchCard(
                              topic: job.topic,
                              status: job.status,
                              date: date,
                              progress: job.progress,
                              onTap: () {
                                if (job.status == 'completed') {
                                  context.go('/jobs/${job.id}/report');
                                } else if (job.status == 'running') {
                                  context.go('/jobs/${job.id}/progress');
                                }
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      itemCount: 5,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: SkeletonResearchCard(),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 32,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No research yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
                letterSpacing: -0.2,
                fontFamily: 'GeneralSans',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your completed research jobs\nwill appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.mutedText,
                height: 1.5,
                fontFamily: 'GeneralSans',
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => context.go('/dashboard'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryText,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Start Research',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.background,
                    fontFamily: 'GeneralSans',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 40,
              color: AppColors.mutedText,
            ),
            const SizedBox(height: 16),
            const Text(
              'Network error',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
                fontFamily: 'GeneralSans',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Unable to load your research history.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.mutedText,
                fontFamily: 'GeneralSans',
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => ref.refresh(jobListProvider),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: const Text(
                  'Try again',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryText,
                    fontFamily: 'GeneralSans',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
