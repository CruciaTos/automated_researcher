import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/desktop_theme.dart';

/// Mobile shell with a bottom navigation bar.
/// On desktop, the router redirects away from these routes before this
/// widget is ever built, so it acts only as a thin pass-through.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final idx      = _indexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => _onTap(context, i),
        backgroundColor:    Dt.bgSidebar,
        indicatorColor:     Dt.primaryLight,
        labelBehavior:
            NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(
            icon:           Icon(Icons.grid_view_outlined),
            selectedIcon:   Icon(Icons.grid_view_rounded, color: Dt.primary),
            label:          'Dashboard',
          ),
          NavigationDestination(
            icon:           Icon(Icons.history_outlined),
            selectedIcon:   Icon(Icons.history_rounded, color: Dt.primary),
            label:          'History',
          ),
          NavigationDestination(
            icon:           Icon(Icons.auto_stories_outlined),
            selectedIcon:   Icon(Icons.auto_stories_rounded, color: Dt.primary),
            label:          'Sources',
          ),
          NavigationDestination(
            icon:           Icon(Icons.person_outline_rounded),
            selectedIcon:   Icon(Icons.person_rounded, color: Dt.primary),
            label:          'Profile',
          ),
        ],
      ),
    );
  }

  int _indexFromLocation(String loc) {
    if (loc.startsWith('/history')) return 1;
    if (loc.startsWith('/sources')) return 2;
    if (loc.startsWith('/profile')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int i) {
    switch (i) {
      case 0: context.go('/dashboard');
      case 1: context.go('/history');
      case 2: context.go('/sources');
      case 3: context.go('/profile');
    }
  }
}
