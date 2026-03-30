import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/job_providers.dart';
import '../../../core/providers/report_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/skeleton_loader.dart';

class SourcesScreen extends ConsumerStatefulWidget {
  const SourcesScreen({super.key});

  @override
  ConsumerState<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends ConsumerState<SourcesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(jobListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Sources',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                        letterSpacing: -0.8,
                        height: 1.1,
                        fontFamily: 'GeneralSans')),
                SizedBox(height: 4),
                Text('All collected references',
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondaryText,
                        fontFamily: 'GeneralSans')),
              ]),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: jobsState.when(
                loading: () => _skeleton(),
                error: (e, __) => _error(
                  message: '$e',
                  onRetry: () => ref.refresh(jobListProvider),
                ),
                data: (jobs) {
                  if (jobs.isEmpty) return _empty();
                  final latest = jobs.first;
                  final srcState = ref.watch(sourcesProvider(latest.id));
                  return srcState.when(
                    loading: () => _skeleton(),
                    error: (e, __) => _error(
                      message: '$e',
                      onRetry: () => ref.refresh(sourcesProvider(latest.id)),
                    ),
                    data: (sources) {
                      if (sources.isEmpty) return _empty();
                      return RefreshIndicator(
                        onRefresh: () =>
                            ref.refresh(sourcesProvider(latest.id).future),
                        color: AppColors.primaryText,
                        backgroundColor: AppColors.surface,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(24, 0, 24, 32),
                          itemCount: sources.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _SourceCard(
                              index: i + 1,
                              title: sources[i].title,
                              url: sources[i].url,
                              snippet: sources[i].snippet,
                              domain: sources[i].domain ?? sources[i].url,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _skeleton() => ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        itemCount: 6,
        itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: SkeletonResearchCard()),
      );

  Widget _empty() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border, width: 1)),
            child: const Icon(Icons.link_off_rounded,
                size: 28, color: AppColors.mutedText),
          ),
          const SizedBox(height: 20),
          const Text('No sources yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                  fontFamily: 'GeneralSans')),
          const SizedBox(height: 8),
          const Text('Sources appear here after your first research job.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText,
                  height: 1.5,
                  fontFamily: 'GeneralSans')),
        ]),
      );

  Widget _error({required String message, required VoidCallback onRetry}) =>
      RefreshIndicator(
        onRefresh: () async => onRetry(),
        color: AppColors.primaryText,
        backgroundColor: AppColors.surface,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            const SizedBox(height: 120),
            const Icon(Icons.error_outline_rounded,
                size: 40, color: AppColors.error),
            const SizedBox(height: 16),
            const Text('Failed to load sources',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                    fontFamily: 'GeneralSans')),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedText,
                    fontFamily: 'GeneralSans')),
            const SizedBox(height: 20),
            Center(
              child: OutlinedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      );
}

class _SourceCard extends StatefulWidget {
  const _SourceCard(
      {required this.index,
      required this.title,
      required this.url,
      required this.snippet,
      required this.domain});
  final int index;
  final String title;
  final String url;
  final String snippet;
  final String domain;

  @override
  State<_SourceCard> createState() => _SourceCardState();
}

class _SourceCardState extends State<_SourceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Color?> _border;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _border = ColorTween(
            begin: AppColors.border, end: AppColors.borderBright)
        .animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _launch() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _ctrl.forward(),
      onExit: (_) => _ctrl.reverse(),
      child: GestureDetector(
        onTap: _launch,
        child: AnimatedBuilder(
          animation: _border,
          builder: (_, child) => Container(
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _border.value ?? AppColors.border, width: 1)),
            child: child,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(7)),
                child: Center(
                  child: Text('${widget.index}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryText,
                          fontFamily: 'GeneralSans')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryText,
                              height: 1.35,
                              fontFamily: 'GeneralSans'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(widget.domain,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.mutedText,
                              fontFamily: 'GeneralSans')),
                      if (widget.snippet.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(widget.snippet,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.secondaryText,
                                height: 1.5,
                                fontFamily: 'GeneralSans'),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ]),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.open_in_new_rounded,
                  size: 14, color: AppColors.mutedText),
            ]),
          ),
        ),
      ),
    );
  }
}
