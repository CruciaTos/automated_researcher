import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import 'app_providers.dart';

// ─── Selection state ──────────────────────────────────────────────────────────

/// ID of the job currently open in the Active Jobs detail panel.
final selectedJobIdProvider = StateProvider<int?>((ref) => null);

/// ID of the job whose report is open in the Reports viewer.
final selectedReportIdProvider = StateProvider<int?>((ref) => null);

// ─── Backend health ───────────────────────────────────────────────────────────

/// Returns true if the FastAPI backend responds to /health.
/// Invalidate this provider to re-check the connection.
final backendHealthProvider = FutureProvider<bool>((ref) async {
  try {
    final client = ref.read(apiClientProvider);
    await client.get('/health');
    return true;
  } catch (_) {
    return false;
  }
});

// ─── Right-panel visibility ───────────────────────────────────────────────────

/// Controls whether the optional right utility panel is visible on screens
/// that support it (Active Jobs, Reports).
final rightPanelVisibleProvider = StateProvider<bool>((ref) => true);
