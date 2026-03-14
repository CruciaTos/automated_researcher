import 'package:flutter/material.dart';
import '../../../core/theme/desktop_theme.dart'; // FIX: was ../../ (wrong depth)
import 'desktop_sidebar.dart';
import 'desktop_top_bar.dart';

/// The root layout for the desktop experience.
/// Wraps the sidebar + top-bar around whatever child screen go_router provides.
///
///  ┌─────────────┬──────────────────────────────────────────────┐
///  │             │  DesktopTopBar (52 px)                       │
///  │  Sidebar    ├──────────────────────────────────────────────┤
///  │  (224 px)   │                                              │
///  │             │  child (screen content)                      │
///  │             │                                              │
///  └─────────────┴──────────────────────────────────────────────┘
class DesktopShell extends StatelessWidget {
  const DesktopShell({
    super.key,
    required this.child,
    this.title = '',
  });

  final Widget child;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Dt.bgPage,
      body: Row(
        children: [
          const DesktopSidebar(),
          Expanded(
            child: Column(
              children: [
                DesktopTopBar(title: title),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
