import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _expanded = false;

  static const _tabs = ['/initialise', '/dashboard', '/history', '/profile'];
  static const _collapsedWidth = 64.0;
  static const _expandedWidth = 200.0;

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    final i = _tabs.indexWhere((t) => loc.startsWith(t));
    return i < 0 ? 0 : i;
  }

  void _toggleRail() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    final railWidth = _expanded ? _expandedWidth : _collapsedWidth;
    final user = FirebaseAuth.instance.currentUser;
    final identity = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : (user?.email?.split('@').first ?? 'Researcher');
    final initial = identity.isNotEmpty ? identity[0].toUpperCase() : 'R';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: EdgeInsets.only(right: railWidth),
            child: widget.child,
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleRail,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: railWidth,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    left: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    child: Column(
                      children: [
                        _RailNavItem(
                          icon: Icons.power_settings_new_rounded,
                          label: 'Engine',
                          isActive: idx == 0,
                          isExpanded: _expanded,
                          onTap: () => context.go(_tabs[0]),
                        ),
                        const SizedBox(height: 6),
                        _RailNavItem(
                          icon: Icons.home_rounded,
                          label: 'Home',
                          isActive: idx == 1,
                          isExpanded: _expanded,
                          onTap: () => context.go(_tabs[1]),
                        ),
                        const SizedBox(height: 6),
                        _RailNavItem(
                          icon: Icons.history_rounded,
                          label: 'History',
                          isActive: idx == 2,
                          isExpanded: _expanded,
                          onTap: () => context.go(_tabs[2]),
                        ),
                        const Spacer(),
                        _ProfileRailItem(
                          isExpanded: _expanded,
                          isActive: idx == 3,
                          identity: identity,
                          initial: initial,
                          hasUser: user != null,
                          onTap: () => context.go(_tabs[3]),
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          _expanded
                              ? Icons.chevron_left_rounded
                              : Icons.chevron_right_rounded,
                          size: 14,
                          color: AppColors.mutedText,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailNavItem extends StatelessWidget {
  const _RailNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isExpanded,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: 36,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentDim : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment:
              isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? AppColors.primaryText : AppColors.mutedText,
            ),
            if (isExpanded) ...[
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? AppColors.primaryText : AppColors.mutedText,
                  fontFamily: 'GeneralSans',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileRailItem extends StatelessWidget {
  const _ProfileRailItem({
    required this.isExpanded,
    required this.isActive,
    required this.identity,
    required this.initial,
    required this.hasUser,
    required this.onTap,
  });

  final bool isExpanded;
  final bool isActive;
  final String identity;
  final String initial;
  final bool hasUser;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: 44,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentDim : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisAlignment:
              isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.borderBright,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: hasUser
                    ? Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                          fontFamily: 'GeneralSans',
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        size: 16,
                        color: AppColors.primaryText,
                      ),
              ),
            ),
            if (isExpanded) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  identity,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                    fontFamily: 'GeneralSans',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
