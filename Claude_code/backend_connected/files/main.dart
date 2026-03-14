import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_router.dart';
import 'core/theme/desktop_theme.dart';

void main() {
  runApp(const ProviderScope(child: ResearcherApp()));
}

class ResearcherApp extends ConsumerWidget {
  const ResearcherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Researcher',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Dt.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Dt.bgPage,
        appBarTheme: const AppBarTheme(
          backgroundColor: Dt.bgSidebar,
          foregroundColor: Dt.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
