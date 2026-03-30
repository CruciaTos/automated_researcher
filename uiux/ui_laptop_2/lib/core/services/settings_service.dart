// lib/core/services/settings_service.dart
//
// LAN SETUP NOTES
// ───────────────
// Physical Android/iOS device on the same Wi-Fi as your laptop:
//   defaultBackendUrl = 'http://<YOUR-LAN-IP>:8000'
//   e.g.               'http://192.168.1.42:8000'
//
// Android emulator (maps host loopback):
//   defaultBackendUrl = 'http://10.0.2.2:8000'
//
// iOS simulator (localhost works directly):
//   defaultBackendUrl = 'http://localhost:8000'
//
// The user can always override this at runtime in Advanced Settings.

import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  // ── Key constants ─────────────────────────────────────────────────────────
  static const _kBackendUrl    = 'backend_url';
  static const _kModelBasic    = 'model_basic';
  static const _kModelStandard = 'model_standard';
  static const _kModelDeep     = 'model_deep';

  // ── LAN SETUP ─────────────────────────────────────────────────────────────
  // Step 1 — find your laptop's IP:
  //   macOS/Linux : ipconfig getifaddr en0    OR    hostname -I
  //   Windows     : ipconfig  (look for "IPv4 Address" under Wi-Fi)
  //
  // Step 2 — start the backend so it's reachable on the LAN:
  //   uvicorn backend.app.main:app --host 0.0.0.0 --port 8000 --reload
  //   (the key flag is --host 0.0.0.0; localhost/127.0.0.1 is laptop-only)
  //
  // Step 3 — set the URL below (or change it at runtime in Advanced Settings):
  //   Physical Android/iOS on same Wi-Fi  →  'http://192.168.x.x:8000'
  //   Android emulator                    →  'http://10.0.2.2:8000'
  //   iOS simulator                       →  'http://localhost:8000'
  //
  // Step 4 (Android physical device only) — allow plain HTTP in
  //   android/app/src/main/AndroidManifest.xml  inside <application>:
  //   android:usesCleartextTraffic="true"
  static const defaultBackendUrl = 'http://192.168.0.103:8000';

  // ── Getters ───────────────────────────────────────────────────────────────

  String get backendUrl =>
      _prefs.getString(_kBackendUrl) ?? defaultBackendUrl;

  String? get modelBasic    => _prefs.getString(_kModelBasic);
  String? get modelStandard => _prefs.getString(_kModelStandard);
  String? get modelDeep     => _prefs.getString(_kModelDeep);

  String? modelForDepth(int depthMinutes) {
    if (depthMinutes <= 10) return modelBasic;
    if (depthMinutes <= 30) return modelStandard;
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

  Future<void> setModels({
    String? basic,
    String? standard,
    String? deep,
  }) async {
    await setModelBasic(basic);
    await setModelStandard(standard);
    await setModelDeep(deep);
  }

  Future<void> clearAll() => _prefs.clear();
}