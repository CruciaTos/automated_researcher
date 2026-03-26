import 'package:shared_preferences/shared_preferences.dart';

/// Persists user-configurable settings across app restarts.
///
/// Keys stored:
///   backend_url    — FastAPI server base URL
///   model_basic    — Ollama model for Quick (≤10 min) jobs
///   model_standard — Ollama model for Standard (≤30 min) jobs
///   model_deep     — Ollama model for Deep (>30 min) jobs
class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  // ── Key constants ─────────────────────────────────────────────────────────
  static const _kBackendUrl    = 'backend_url';
  static const _kModelBasic    = 'model_basic';
  static const _kModelStandard = 'model_standard';
  static const _kModelDeep     = 'model_deep';

  /// Default URL for Android emulator. Change to your machine's LAN IP
  /// (e.g. http://192.168.1.5:8000) when running on a physical device.
  static const defaultBackendUrl = 'http://10.0.2.2:8000';

  // ── Getters ───────────────────────────────────────────────────────────────

  String get backendUrl =>
      _prefs.getString(_kBackendUrl) ?? defaultBackendUrl;

  /// Returns null when the user has not chosen a model → backend default used.
  String? get modelBasic    => _prefs.getString(_kModelBasic);
  String? get modelStandard => _prefs.getString(_kModelStandard);
  String? get modelDeep     => _prefs.getString(_kModelDeep);

  /// Returns the persisted model for the given depth in minutes.
  String? modelForDepth(int depthMinutes) {
    if (depthMinutes <= 10)  return modelBasic;
    if (depthMinutes <= 30)  return modelStandard;
    return modelDeep;
  }

  // ── Setters ───────────────────────────────────────────────────────────────

  Future<void> setBackendUrl(String url) =>
      _prefs.setString(_kBackendUrl, url.trim());

  Future<void> setModelBasic(String? model) =>
      model != null && model.isNotEmpty
          ? _prefs.setString(_kModelBasic, model)
          : _prefs.remove(_kModelBasic);

  Future<void> setModelStandard(String? model) =>
      model != null && model.isNotEmpty
          ? _prefs.setString(_kModelStandard, model)
          : _prefs.remove(_kModelStandard);

  Future<void> setModelDeep(String? model) =>
      model != null && model.isNotEmpty
          ? _prefs.setString(_kModelDeep, model)
          : _prefs.remove(_kModelDeep);

  /// Convenience: persist all model prefs at once.
  Future<void> setModels({
    String? basic,
    String? standard,
    String? deep,
  }) async {
    await setModelBasic(basic);
    await setModelStandard(standard);
    await setModelDeep(deep);
  }

  /// Wipe everything — useful for "Reset to defaults".
  Future<void> clearAll() => _prefs.clear();
}
