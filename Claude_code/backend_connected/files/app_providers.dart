import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

/// Provides the singleton [ApiClient] pointing at the local backend.
///
/// Override in widget tests:
/// ```dart
/// ProviderScope(
///   overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
///   child: MyApp(),
/// )
/// ```
final apiClientProvider = Provider<ApiClient>((ref) {
  return const ApiClient(baseUrl: 'http://localhost:8000');
});
