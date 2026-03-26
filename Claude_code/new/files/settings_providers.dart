import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/settings_service.dart';

// ── Foundation ────────────────────────────────────────────────────────────

/// Overridden in main.dart before runApp with the already-awaited instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main() before runApp()',
  ),
);

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService(ref.watch(sharedPreferencesProvider));
});

// ── Backend URL ───────────────────────────────────────────────────────────

/// Mutable — updated by AdvancedSettingsSheet when the user saves.
/// apiClientProvider depends on this, so all data providers rebuild on change.
final backendUrlProvider = StateProvider<String>((ref) {
  return ref.watch(settingsServiceProvider).backendUrl;
});

// ── Model preferences ─────────────────────────────────────────────────────

class ModelPreferences {
  const ModelPreferences({this.basic, this.standard, this.deep});

  /// null = use server-configured default (OLLAMA_MODEL env var)
  final String? basic;
  final String? standard;
  final String? deep;

  String? forDepth(int depthMinutes) {
    if (depthMinutes <= 10) return basic;
    if (depthMinutes <= 30) return standard;
    return deep;
  }
}

class ModelPreferencesNotifier extends StateNotifier<ModelPreferences> {
  ModelPreferencesNotifier(this._settings)
      : super(ModelPreferences(
          basic: _settings.modelBasic,
          standard: _settings.modelStandard,
          deep: _settings.modelDeep,
        ));

  final SettingsService _settings;

  Future<void> update({
    String? basic,
    String? standard,
    String? deep,
  }) async {
    await _settings.setModels(basic: basic, standard: standard, deep: deep);
    state = ModelPreferences(
      basic: _settings.modelBasic,
      standard: _settings.modelStandard,
      deep: _settings.modelDeep,
    );
  }
}

final modelPreferencesProvider =
    StateNotifierProvider<ModelPreferencesNotifier, ModelPreferences>((ref) {
  return ModelPreferencesNotifier(ref.watch(settingsServiceProvider));
});

// ── Available Ollama models ───────────────────────────────────────────────

/// Fetches pulled Ollama models from GET /health/models.
/// Invalidate with ref.invalidate(availableModelsProvider) after URL change.
final availableModelsProvider = FutureProvider<List<String>>((ref) async {
  final baseUrl = ref.watch(backendUrlProvider);
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 15),
  ));
  final response = await dio.get('/health/models');
  final data = response.data as Map<String, dynamic>;
  return List<String>.from(data['models'] as List? ?? []);
});
