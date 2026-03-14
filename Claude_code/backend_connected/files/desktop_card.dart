import 'package:flutter/material.dart';
import '../theme/desktop_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DesktopCard
// ─────────────────────────────────────────────────────────────────────────────

/// A padded, bordered card for desktop layouts.
class DesktopCard extends StatelessWidget {
  const DesktopCard({
    super.key,
    required this.child,
    this.padding,
    this.elevated = false,
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool elevated;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final decoration = elevated ? Dt.cardElevated : Dt.card;
    final effective  = color != null
        ? decoration.copyWith(color: color)
        : decoration;

    Widget container = Container(
      padding:    padding ?? const EdgeInsets.all(20),
      decoration: effective,
      child:      child,
    );

    if (onTap != null) {
      container = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap:  onTap,
          child:  container,
        ),
      );
    }
    return container;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SectionHeader
// ─────────────────────────────────────────────────────────────────────────────

/// An uppercase label used to group content on a desktop screen.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String  title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(title.toUpperCase(), style: Dt.sectionLabel),
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// EmptyState
// ─────────────────────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String   title;
  final String?  subtitle;
  final Widget?  action;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width:  56,
              height: 56,
              decoration: BoxDecoration(
                color:  Dt.bgMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 26, color: Dt.textMuted),
            ),
            const SizedBox(height: 16),
            Text(title, style: Dt.cardTitle),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, style: Dt.bodySm,
                  textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// DtDivider
// ─────────────────────────────────────────────────────────────────────────────

class DtDivider extends StatelessWidget {
  const DtDivider({super.key, this.horizontal = false});
  final bool horizontal;

  @override
  Widget build(BuildContext context) => horizontal
      ? const Divider(height: 1, thickness: 1, color: Dt.border)
      : const VerticalDivider(width: 1, thickness: 1, color: Dt.border);
}

// ─────────────────────────────────────────────────────────────────────────────
// PipelineStageRow
// ─────────────────────────────────────────────────────────────────────────────

class PipelineStageRow extends StatelessWidget {
  const PipelineStageRow({
    super.key,
    required this.label,
    required this.state, // 'done' | 'active' | 'pending'
  });

  final String label;
  final String state;

  @override
  Widget build(BuildContext context) {
    final isDone   = state == 'done';
    final isActive = state == 'active';

    Color    dotColor;
    IconData? dotIcon;
    if (isDone) {
      dotColor = Dt.success;
      dotIcon  = Icons.check_rounded;
    } else if (isActive) {
      dotColor = Dt.primary;
      dotIcon  = null;
    } else {
      dotColor = Dt.border;
      dotIcon  = null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width:  22,
            height: 22,
            decoration: BoxDecoration(
              color: isDone
                  ? Dt.successBg
                  : (isActive ? Dt.primaryLight : Dt.bgMuted),
              shape: BoxShape.circle,
              border: isActive
                  ? Border.all(color: Dt.primary, width: 2)
                  : null,
            ),
            child: dotIcon != null
                ? Icon(dotIcon, size: 13, color: dotColor)
                : isActive
                    ? Center(
                        child: Container(
                          width:  7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  isActive ? FontWeight.w600 : FontWeight.w400,
              color: isDone
                  ? Dt.textSecondary
                  : (isActive ? Dt.textPrimary : Dt.textMuted),
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 8),
            SizedBox(
              width:  12,
              height: 12,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Dt.primary),
            ),
          ],
        ],
      ),
    );
  }
}
