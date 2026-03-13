import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/desktop_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Navigation model
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });

  final String    label;
  final IconData  icon;
  final IconData  activeIcon;
  final String    route;
}

const _topItems = <_NavItem>[
  _NavItem(
    label:      'Dashboard',
    icon:       Icons.grid_view_outlined,
    activeIcon: Icons.grid_view_rounded,
    route:      '/desktop/dashboard',
  ),
  _NavItem(
    label:      'New Research',
    icon:       Icons.add_circle_outline_rounded,
    activeIcon: Icons.add_circle_rounded,
    route:      '/desktop/new-research',
  ),
  _NavItem(
    label:      'Active Jobs',
    icon:       Icons.pending_outlined,
    activeIcon: Icons.pending_rounded,
    route:      '/desktop/jobs',
  ),
  _NavItem(
    label:      'Reports',
    icon:       Icons.description_outlined,
    activeIcon: Icons.description_rounded,
    route:      '/desktop/reports',
  ),
  _NavItem(
    label:      'Knowledge Base',
    icon:       Icons.auto_stories_outlined,
    activeIcon: Icons.auto_stories_rounded,
    route:      '/desktop/knowledge-base',
  ),
];

const _bottomItems = <_NavItem>[
  _NavItem(
    label:      'Settings',
    icon:       Icons.tune_outlined,
    activeIcon: Icons.tune_rounded,
    route:      '/desktop/settings',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// DesktopSidebar
// ─────────────────────────────────────────────────────────────────────────────

class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return SizedBox(
      width: Dt.sidebarWidth,
      child: Container(
        decoration: Dt.sidebar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Brand area ────────────────────────────────────────────────
            _BrandArea(),
            const SizedBox(height: 8),

            // ── Top nav items ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('WORKSPACE', style: Dt.sectionLabel),
            ),
            const SizedBox(height: 6),
            for (final item in _topItems)
              _SidebarNavItem(
                item:     item,
                isActive: location.startsWith(item.route),
              ),

            const Spacer(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: DtHorizontalDivider(),
            ),
            const SizedBox(height: 6),

            // ── Bottom nav items ──────────────────────────────────────────
            for (final item in _bottomItems)
              _SidebarNavItem(
                item:     item,
                isActive: location.startsWith(item.route),
              ),

            // ── User area ─────────────────────────────────────────────────
            _UserArea(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Brand area
// ─────────────────────────────────────────────────────────────────────────────

class _BrandArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: Dt.topBarHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Dt.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Dt.primary,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.biotech_rounded, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              'Researcher',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Dt.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav item
// ─────────────────────────────────────────────────────────────────────────────

class _SidebarNavItem extends StatefulWidget {
  const _SidebarNavItem({required this.item, required this.isActive});

  final _NavItem item;
  final bool     isActive;

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isActive
        ? Dt.primaryLight
        : _hovered
            ? const Color(0xFFF8FAFC)
            : Colors.transparent;

    final fgColor = widget.isActive ? Dt.primary : Dt.textSecondary;
    final iconData = widget.isActive ? widget.item.activeIcon : widget.item.icon;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter:  (_) => setState(() => _hovered = true),
        onExit:   (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => context.go(widget.item.route),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(Dt.navItemRadius),
            ),
            child: Row(
              children: [
                Icon(iconData, size: 17, color: fgColor),
                const SizedBox(width: 9),
                Text(
                  widget.item.label,
                  style: Dt.navItem.copyWith(color: fgColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User area
// ─────────────────────────────────────────────────────────────────────────────

class _UserArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Dt.bgMuted,
            borderRadius: BorderRadius.circular(Dt.navItemRadius),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Dt.primaryLight,
                child: const Icon(Icons.person_outline_rounded, size: 15, color: Dt.primary),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'User',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Dt.textPrimary),
                    ),
                    const Text(
                      'Researcher',
                      style: TextStyle(fontSize: 11, color: Dt.textMuted),
                    ),
                  ],
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.go('/login'),
                  child: const Icon(Icons.logout_rounded, size: 15, color: Dt.textMuted),
                ),
              ),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// DtHorizontalDivider (local helper)
// ─────────────────────────────────────────────────────────────────────────────
class DtHorizontalDivider extends StatelessWidget {
  const DtHorizontalDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: Dt.border);
}
