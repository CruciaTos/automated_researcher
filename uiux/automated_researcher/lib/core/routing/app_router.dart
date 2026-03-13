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

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
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