import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/initialise/presentation/initialise_screen.dart';
import '../features/navigation/presentation/main_shell.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/report/presentation/report_screen.dart';
import '../features/report/presentation/report_viewer_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/initialise',
            pageBuilder: (context, state) =>
                _fadeTransition(const InitialiseScreen()),
          ),
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                _fadeTransition(const DashboardScreen()),
          ),
          GoRoute(
            path: '/history',
            pageBuilder: (context, state) =>
                _fadeTransition(const HistoryScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                _fadeTransition(const ProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/jobs/:id/progress',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _slideUpTransition(ProgressScreen(jobId: id));
        },
      ),
      GoRoute(
        path: '/jobs/:id/report',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _slideUpTransition(ReportScreen(jobId: id));
        },
      ),
      GoRoute(
        path: '/jobs/:id/report/viewer',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _slideTransition(ReportViewerScreen(jobId: id));
        },
      ),
      GoRoute(
        path: '/jobs/:id/chat',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return _slideTransition(ChatScreen(jobId: id));
        },
      ),
    ],
  );
});

CustomTransitionPage<void> _fadeTransition(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionsBuilder: (context, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 250),
  );
}

CustomTransitionPage<void> _slideTransition(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionsBuilder: (context, animation, _, child) {
      final tween = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(
          position: animation.drive(tween), child: child);
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}

CustomTransitionPage<void> _slideUpTransition(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionsBuilder: (context, animation, _, child) {
      final slide = Tween<Offset>(
        begin: const Offset(0.0, 0.06),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);

      return FadeTransition(
        opacity:
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: SlideTransition(position: slide, child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}
