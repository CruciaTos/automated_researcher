import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ResearchCard extends StatefulWidget {
  const ResearchCard({
    super.key,
    required this.topic,
    required this.status,
    required this.date,
    required this.onTap,
    this.progress = 0,
  });

  final String topic;
  final String status;
  final String date;
  final VoidCallback onTap;
  final int progress;

  @override
  State<ResearchCard> createState() => _ResearchCardState();
}

class _ResearchCardState extends State<ResearchCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Color?> _border;

  static const _inProgressStatuses = {
    'queued', 'running', 'retrieving_sources', 'fetching_documents',
    'chunking_documents', 'embedding_documents', 'drafting_outline',
    'writing_report',
  };

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

  Color get _statusColor {
    if (widget.status == 'completed') return AppColors.success;
    if (widget.status == 'failed') return AppColors.error;
    if (_inProgressStatuses.contains(widget.status)) return AppColors.warning;
    return AppColors.mutedText;
  }

  String get _statusLabel {
    if (widget.status == 'completed') return 'Completed';
    if (widget.status == 'failed') return 'Failed';
    if (widget.status == 'queued') return 'Queued';
    if (_inProgressStatuses.contains(widget.status)) return 'In Progress';
    return widget.status;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _ctrl.forward(),
      onExit: (_) => _ctrl.reverse(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _border,
          builder: (_, child) => Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _border.value ?? AppColors.border, width: 1),
            ),
            child: child,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(widget.topic,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryText,
                              height: 1.3,
                              fontFamily: 'GeneralSans'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.mutedText, size: 18),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: _statusColor,
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(_statusLabel,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _statusColor,
                                  letterSpacing: 0.3,
                                  fontFamily: 'GeneralSans')),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(widget.date,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText,
                            fontFamily: 'GeneralSans')),
                  ],
                ),
                if (_inProgressStatuses.contains(widget.status)) ...[
                  const SizedBox(height: 14),
                  Stack(
                    children: [
                      Container(
                          height: 2,
                          decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(1))),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        height: 2,
                        width: MediaQuery.of(context).size.width *
                            widget.progress /
                            100 *
                            0.7,
                        decoration: BoxDecoration(
                            color: AppColors.primaryText,
                            borderRadius: BorderRadius.circular(1)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
