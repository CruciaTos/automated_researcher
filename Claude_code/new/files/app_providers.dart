import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/job_service.dart';
import 'settings_providers.dart';

// ── Auth ───────────────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

/// Streams the Firebase auth state so widgets can rebuild on sign-in/out.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// ── API / Job ──────────────────────────────────────────────────────────────

/// Rebuilds automatically when backendUrlProvider changes (user saved new URL
/// in Advanced Settings). Every downstream provider chain rebuilds too.
final apiClientProvider = Provider<ApiClient>((ref) {
  final baseUrl = ref.watch(backendUrlProvider);
  return ApiClient(baseUrl: baseUrl);
});

final jobServiceProvider = Provider<JobService>((ref) {
  return JobService(ref.watch(apiClientProvider));
});
