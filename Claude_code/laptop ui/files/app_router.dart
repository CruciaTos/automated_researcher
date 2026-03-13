import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../../features/report/presentation/report_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/sources/presentation/sources_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/report/presentation/report_viewer_screen.dart';
import '../../features/navigation/presentation/main_shell.dart';

// Desktop imports
import '../../features/navigation/presentation/desktop_shell.dart';
import '../../features/desktop/dashboard/desktop_dashboard_screen.dart';
import '../../features/desktop/new_research/desktop_new_research_screen.dart';
import '../../features/desktop/active_jobs/desktop_active_jobs_screen.dart';
import '../../features/desktop/reports/desktop_reports_screen.dart';
import '../../features/desktop/knowledge_base/desktop_knowledge_base_screen.dart';
import '../../features/desktop/settings/desktop_settings_screen.dart';

// ─── Platform helper ──────────────────────────────────────────────────────────

bool _isDesktopPlatform() {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;
}

// ─── Router provider ──────────────────────────────────────────────────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',

    // ── After login, route to the correct shell based on platform ──────────
    redirect: (context, state) {
      if (!_isDesktopPlatform()) return null;
      final loc = state.matchedLocation;
      // Redirect mobile-first paths to their desktop equivalents
      if (loc == '/dashboard') return '/desktop/dashboard';
      if (loc == '/history')   return '/desktop/reports';
      if (loc == '/sources')   return '/desktop/knowledge-base';
      if (loc == '/profile')   return '/desktop/settings';
      return null;
    },

    routes: [
      // ────────────────────────────────────────────────────────────────────
      // Shared: Login
      // ────────────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ────────────────────────────────────────────────────────────────────
      // Desktop shell + feature routes
      // ────────────────────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => DesktopShell(child: child),
        routes: [
          GoRoute(
            path: '/desktop/dashboard',
            builder: (context, state) => const DesktopDashboardScreen(),
          ),
          GoRoute(
            path: '/desktop/new-research',
            builder: (context, state) => const DesktopNewResearchScreen(),
          ),
          GoRoute(
            path: '/desktop/jobs',
            builder: (context, state) => const DesktopActiveJobsScreen(),
          ),
          GoRoute(
            path: '/desktop/reports',
            builder: (context, state) => const DesktopReportsScreen(),
          ),
          GoRoute(
            path: '/desktop/knowledge-base',
            builder: (context, state) => const DesktopKnowledgeBaseScreen(),
          ),
          GoRoute(
            path: '/desktop/settings',
            builder: (context, state) => const DesktopSettingsScreen(),
          ),
        ],
      ),

      // ────────────────────────────────────────────────────────────────────
      // Mobile shell + feature routes (unchanged)
      // ────────────────────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/sources',
            builder: (context, state) => const SourcesScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // ────────────────────────────────────────────────────────────────────
      // Shared full-screen routes (progress, report viewer, chat)
      // These are used by both mobile and desktop flows
      // ────────────────────────────────────────────────────────────────────
      GoRoute(
        path: '/jobs/:id/progress',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ProgressScreen(jobId: id);
        },
      ),
      GoRoute(
        path: '/jobs/:id/report',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ReportScreen(jobId: id);
        },
      ),
      GoRoute(
        path: '/jobs/:id/report/viewer',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ReportViewerScreen(jobId: id);
        },
      ),
      GoRoute(
        path: '/jobs/:id/chat',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ChatScreen(jobId: id);
        },
      ),
    ],
  );
});
