import 'package:flutter/material.dart';
import '../theme/desktop_theme.dart';

/// Compact status pill for a research job.
class JobStatusBadge extends StatelessWidget {
  const JobStatusBadge(this.status, {super.key, this.showDot = true});

  final String status;
  final bool   showDot;

  @override
  Widget build(BuildContext context) {
    final colors   = Dt.statusColors(status);
    final label    = Dt.statusLabel(status);
    final isActive = status == 'retrieving_sources'  ||
                     status == 'fetching_documents'  ||
                     status == 'chunking_documents'  ||
                     status == 'embedding_documents' ||
                     status == 'drafting_outline'    ||
                     status == 'writing_report';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:  colors.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            isActive
                ? _PulsingDot(color: colors.fg)
                : Container(
                    width:  6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colors.fg,
                      shape: BoxShape.circle,
                    ),
                  ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize:    11,
              fontWeight:  FontWeight.w600,
              color:       colors.fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _anim,
        child: Container(
          width:  6,
          height: 6,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      );
}
