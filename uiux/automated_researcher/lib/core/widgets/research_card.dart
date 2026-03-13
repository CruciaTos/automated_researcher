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
  late final AnimationController _controller;
  late final Animation<Color?> _borderColor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _borderColor = ColorTween(
      begin: AppColors.border,
      end: AppColors.borderBright,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _statusColor {
    switch (widget.status) {
      case 'completed':
        return AppColors.success;
      case 'running':
        return AppColors.warning;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.mutedText;
    }
  }

  String get _statusLabel {
    switch (widget.status) {
      case 'completed':
        return 'Completed';
      case 'running':
        return 'In Progress';
      case 'failed':
        return 'Failed';
      default:
        return widget.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _borderColor,
          builder: (context, child) => Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _borderColor.value ?? AppColors.border,
                width: 1,
              ),
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
                      child: Text(
                        widget.topic,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryText,
                          height: 1.3,
                          fontFamily: 'GeneralSans',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.mutedText,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.12),
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
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _statusColor,
                              letterSpacing: 0.3,
                              fontFamily: 'GeneralSans',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText,
                        fontFamily: 'GeneralSans',
                      ),
                    ),
                  ],
                ),
                if (widget.status == 'running') ...[
                  const SizedBox(height: 14),
                  Stack(
                    children: [
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
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
                          borderRadius: BorderRadius.circular(1),
                        ),
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
