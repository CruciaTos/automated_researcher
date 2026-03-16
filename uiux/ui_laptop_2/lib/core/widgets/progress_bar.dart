import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ResearchProgressBar extends StatefulWidget {
  const ResearchProgressBar({
    super.key,
    required this.progress,
    this.height = 3,
    this.showPulse = false,
  });

  final double progress;
  final double height;
  final bool showPulse;

  @override
  State<ResearchProgressBar> createState() => _ResearchProgressBarState();
}

class _ResearchProgressBarState extends State<ResearchProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth * widget.progress.clamp(0.0, 1.0);
        return Stack(
          children: [
            Container(
              height: widget.height,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius:
                      BorderRadius.circular(widget.height / 2)),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              height: widget.height,
              width: w,
              decoration: BoxDecoration(
                  color: AppColors.primaryText,
                  borderRadius:
                      BorderRadius.circular(widget.height / 2)),
            ),
            if (widget.showPulse &&
                widget.progress > 0 &&
                widget.progress < 1)
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Positioned(
                  left: w - widget.height * 2,
                  child: Container(
                    height: widget.height,
                    width: widget.height * 4,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(widget.height / 2),
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        AppColors.primaryText.withAlpha(
                            (_pulseAnim.value * 255).toInt()),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
