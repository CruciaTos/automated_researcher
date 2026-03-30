import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:uiux/core/services/settings_service.dart';

import '../../../core/providers/settings_providers.dart';
import '../../../core/theme/app_theme.dart';

/// A Claude-style modal bottom sheet that lets the user configure:
///   1. Backend URL  — where the FastAPI server is running
///   2. Per-depth Ollama model — which local model to use for Quick / Standard / Deep
///
/// Usage:
///   AdvancedSettingsSheet.show(context);
class AdvancedSettingsSheet extends ConsumerStatefulWidget {
  const AdvancedSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AdvancedSettingsSheet(),
    );
  }

  @override
  ConsumerState<AdvancedSettingsSheet> createState() =>
      _AdvancedSettingsSheetState();
}

class _AdvancedSettingsSheetState
    extends ConsumerState<AdvancedSettingsSheet> {
  late final TextEditingController _urlCtrl;

  // Locally selected models — null means "use server default"
  String? _selectedBasic;
  String? _selectedStandard;
  String? _selectedDeep;

  bool _isSaving = false;
  bool _urlEdited = false;
  String? _connectionStatus; // null | 'ok' | 'error'
  String? _connectionDetail;

  // LAN diagnostics state
  bool _diagLoading = false;
  bool? _diagOk;
  String? _diagDetail;
  String _diagBaseUrl = '';
  List<String> _diagModels = const [];

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsServiceProvider);
    _urlCtrl = TextEditingController(text: settings.backendUrl);
    _selectedBasic    = settings.modelBasic;
    _selectedStandard = settings.modelStandard;
    _selectedDeep     = settings.modelDeep;
    _diagBaseUrl = settings.backendUrl;
    _urlCtrl.addListener(() => setState(() => _urlEdited = true));

    // Auto-run diagnostics on load using the saved URL.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConnection(
        overrideUrl: settings.backendUrl,
        persistUrl: false,
      );
    });
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  // ── Test + load models ──────────────────────────────────────────────────

  Future<void> _connectAndLoad() async {
    await _checkConnection();
  }

  Future<void> _checkConnection({
    String? overrideUrl,
    bool persistUrl = true,
  }) async {
    final url = (overrideUrl ?? _urlCtrl.text).trim();
    if (url.isEmpty) return;

    setState(() {
      _diagLoading = true;
      _diagBaseUrl = url;
      _diagDetail = null;
      _connectionStatus = null;
      _connectionDetail = null;
    });

    if (persistUrl) {
      // Persist URL first so providers rebuild against this base URL.
      await ref.read(settingsServiceProvider).setBackendUrl(url);
      ref.read(backendUrlProvider.notifier).state = url;
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    bool ok = false;
    String? detail;
    List<String> models = const [];

    try {
      await dio.get('/health');
      final modelsRes = await dio.get('/health/models');
      final data = modelsRes.data as Map<String, dynamic>;
      models = List<String>.from(data['models'] as List? ?? []);
      ok = true;

      // Keep model selector provider in sync with diagnostics check.
      ref.invalidate(availableModelsProvider);
      await ref.read(availableModelsProvider.future);
    } catch (e) {
      detail = e.toString();
    }

    if (!mounted) return;
    setState(() {
      _diagLoading = false;
      _diagOk = ok;
      _diagModels = models;
      _diagDetail = detail;
      _connectionStatus = ok ? 'ok' : 'error';
      _connectionDetail = detail;
      _urlEdited = false;
    });
  }

  // ── Save ────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final url = _urlCtrl.text.trim();
    final settings = ref.read(settingsServiceProvider);

    // Persist URL if changed
    if (_urlEdited || url != ref.read(backendUrlProvider)) {
      await settings.setBackendUrl(url);
      ref.read(backendUrlProvider.notifier).state = url;
    }

    // Persist model prefs
    await ref.read(modelPreferencesProvider.notifier).update(
          basic:    _selectedBasic,
          standard: _selectedStandard,
          deep:     _selectedDeep,
        );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final modelsAsync = ref.watch(availableModelsProvider);
    final currentBaseUrl = ref.watch(backendUrlProvider);
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomPad),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ──────────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 14),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ───────────────────────────────────────────────────
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.settings_outlined,
                    size: 18, color: AppColors.secondaryText),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Advanced Settings',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                            letterSpacing: -0.2,
                            fontFamily: 'GeneralSans')),
                    Text('Backend connection & model selection',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText,
                            fontFamily: 'GeneralSans')),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: 28),
            if (Platform.isWindows) ...[
              _sectionLabel('BACKEND ENGINE'),
              const SizedBox(height: 10),
              _BackendEngineLauncher(
                currentBaseUrl: currentBaseUrl,
                onRunning: _checkConnection,
              ),
              const SizedBox(height: 28),
            ],
            _sectionLabel('BACKEND SERVER'),
            const SizedBox(height: 10),

            // ── URL input row ─────────────────────────────────────────────
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: _textField(
                  controller: _urlCtrl,
                  hint: 'http://10.0.2.2:8000',
                  keyboardType: TextInputType.url,
                  onChanged: (_) => setState(() {
                    _urlEdited = true;
                    _connectionStatus = null;
                  }),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: _PillButton(
                  label: 'Connect',
                  icon: Icons.cable_rounded,
                  onTap: _connectAndLoad,
                ),
              ),
            ]),

            // ── Connection status banner ──────────────────────────────────
            if (_connectionStatus != null) ...[
              const SizedBox(height: 10),
              _StatusBanner(
                ok: _connectionStatus == 'ok',
                detail: _connectionStatus == 'ok'
                    ? 'Connected — models loaded'
                    : (_connectionDetail ?? 'Could not reach server'),
              ),
            ],

            const SizedBox(height: 28),
            _sectionLabel('LAN DIAGNOSTICS'),
            const SizedBox(height: 10),
            _DiagnosticsCard(
              baseUrl: _diagBaseUrl,
              isLoading: _diagLoading,
              isOk: _diagOk,
              detail: _diagDetail,
              models: _diagModels,
              onRefresh: _checkConnection,
            ),

            const SizedBox(height: 28),
            _sectionLabel('MODEL PER DEPTH LEVEL'),
            const SizedBox(height: 6),
            const Text(
              'Choose which locally-available Ollama model runs for each research depth. '
              'Press Connect above to load your installed models.',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedText,
                  height: 1.5,
                  fontFamily: 'GeneralSans'),
            ),
            const SizedBox(height: 16),

            // ── Model selectors ───────────────────────────────────────────
            modelsAsync.when(
              loading: () => const _ModelsLoadingState(),
              error: (e, _) => _ModelsErrorState(message: e.toString()),
              data: (models) => Column(
                children: [
                  _ModelSelector(
                    depthLabel: 'Quick',
                    depthSublabel: '≤ 10 min · Wikipedia only',
                    icon: Icons.flash_on_rounded,
                    models: models,
                    selected: _selectedBasic,
                    onChanged: (v) => setState(() => _selectedBasic = v),
                  ),
                  const SizedBox(height: 12),
                  _ModelSelector(
                    depthLabel: 'Standard',
                    depthSublabel: '≤ 30 min · Wikipedia + arXiv',
                    icon: Icons.search_rounded,
                    models: models,
                    selected: _selectedStandard,
                    onChanged: (v) => setState(() => _selectedStandard = v),
                  ),
                  const SizedBox(height: 12),
                  _ModelSelector(
                    depthLabel: 'Deep',
                    depthSublabel: '> 30 min · Full verified research',
                    icon: Icons.travel_explore_rounded,
                    models: models,
                    selected: _selectedDeep,
                    onChanged: (v) => setState(() => _selectedDeep = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Save button ───────────────────────────────────────────────
            _SaveButton(onTap: _save, isLoading: _isSaving),
            const SizedBox(height: 8),

            // ── Reset link ────────────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: () async {
                  await ref.read(settingsServiceProvider).clearAll();
                  const def = SettingsService.defaultBackendUrl;
                  _urlCtrl.text = def;
                  ref.read(backendUrlProvider.notifier).state = def;
                  await ref
                      .read(modelPreferencesProvider.notifier)
                      .update(basic: null, standard: null, deep: null);
                  setState(() {
                    _selectedBasic = null;
                    _selectedStandard = null;
                    _selectedDeep = null;
                    _connectionStatus = null;
                  });
                },
                child: const Text('Reset to defaults',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.mutedText,
                        fontFamily: 'GeneralSans')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared sub-widgets ────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.mutedText,
          letterSpacing: 0.8,
          fontFamily: 'GeneralSans'));

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(
            fontSize: 13,
            color: AppColors.primaryText,
            fontFamily: 'GeneralSans'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 13,
              fontFamily: 'GeneralSans'),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        ),
      ),
    );
  }
}

enum _BackendEngineStatus { idle, starting, running, failed }

class _BackendEngineLauncher extends StatefulWidget {
  const _BackendEngineLauncher({
    required this.currentBaseUrl,
    required this.onRunning,
  });

  final String currentBaseUrl;
  final Future<void> Function() onRunning;

  @override
  State<_BackendEngineLauncher> createState() => _BackendEngineLauncherState();
}

class _BackendEngineLauncherState extends State<_BackendEngineLauncher>
    with TickerProviderStateMixin {
  late final AnimationController _borderController;
  late final AnimationController _pulseController;

  _BackendEngineStatus _status = _BackendEngineStatus.idle;

  @override
  void initState() {
    super.initState();
    _borderController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _initHealthState();
  }

  @override
  void dispose() {
    _borderController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initHealthState() async {
    final isRunning = await _pingHealth();
    if (!mounted) return;
    setState(() {
      _status = isRunning ? _BackendEngineStatus.running : _BackendEngineStatus.idle;
    });
    if (isRunning) {
      await widget.onRunning();
    }
  }

  Future<bool> _pingHealth() async {
    try {
      final healthUri = Uri.parse(widget.currentBaseUrl).resolve('/health');
      final response =
          await http.get(healthUri).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void _startPulseForState(_BackendEngineStatus status) {
    if (status == _BackendEngineStatus.idle) {
      _pulseController
        ..duration = const Duration(seconds: 2)
        ..repeat(reverse: true);
      return;
    }
    if (status == _BackendEngineStatus.starting) {
      _pulseController
        ..duration = const Duration(seconds: 1)
        ..repeat(reverse: true);
      return;
    }
    _pulseController.stop();
  }

  Future<void> _handleTap() async {
    if (_status == _BackendEngineStatus.starting) return;
    if (_status == _BackendEngineStatus.running) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already running on LAN')),
      );
      return;
    }

    setState(() {
      _status = _BackendEngineStatus.starting;
    });
    _startPulseForState(_BackendEngineStatus.starting);

    final healthyBeforeLaunch = await _pingHealth();
    if (healthyBeforeLaunch) {
      if (!mounted) return;
      setState(() {
        _status = _BackendEngineStatus.running;
      });
      _startPulseForState(_BackendEngineStatus.running);
      await widget.onRunning();
      return;
    }

    try {
      await Process.start(
        'cmd.exe',
        [
          '/k',
          'cd /d C:\\Users\\Soham\\ai_teacher && conda activate ai_teacher && uvicorn backend.app.main:app --host 0.0.0.0 --port 8000',
        ],
        mode: ProcessStartMode.detached,
        runInShell: true,
      );
    } catch (_) {}

    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      final healthy = await _pingHealth();
      if (healthy) {
        if (!mounted) return;
        setState(() {
          _status = _BackendEngineStatus.running;
        });
        _startPulseForState(_BackendEngineStatus.running);
        await widget.onRunning();
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _status = _BackendEngineStatus.failed;
    });
    _startPulseForState(_BackendEngineStatus.failed);
  }

  @override
  Widget build(BuildContext context) {
    final buttonLabel = switch (_status) {
      _BackendEngineStatus.idle => "It's Time Baby 🚀",
      _BackendEngineStatus.starting => 'Starting...',
      _BackendEngineStatus.running => 'Backend Running ✓',
      _BackendEngineStatus.failed => 'Failed — Tap to Retry',
    };

    final statusLine = switch (_status) {
      _BackendEngineStatus.idle => 'Backend is offline',
      _BackendEngineStatus.starting => 'Launching backend on LAN...',
      _BackendEngineStatus.running => 'Live at ${widget.currentBaseUrl}',
      _BackendEngineStatus.failed => 'Could not reach backend after 20s',
    };

    final iconWidget = switch (_status) {
      _BackendEngineStatus.idle =>
        const Text('🚀', style: TextStyle(fontSize: 16, height: 1.0)),
      _BackendEngineStatus.starting => const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      _BackendEngineStatus.running => const Text(
          '✓',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF00FF88),
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
      _BackendEngineStatus.failed => const Icon(
          Icons.refresh_rounded,
          size: 16,
          color: Colors.white,
        ),
    };

    return AnimatedBuilder(
      animation: Listenable.merge([_borderController, _pulseController]),
      builder: (context, child) {
        final t = _borderController.value;
        final pulseValue = _pulseController.value;

        final alignX = math.cos(t * 2 * math.pi);
        final alignY = math.sin(t * 2 * math.pi);

        final glowColor = switch (_status) {
          _BackendEngineStatus.running => const Color(0xFF00FF88),
          _BackendEngineStatus.failed => const Color(0xFFFF4D4D),
          _ => const Color(0xFF8B5CF6),
        };

        final spread = switch (_status) {
          _BackendEngineStatus.idle || _BackendEngineStatus.starting =>
            2.0 + (pulseValue * 6.0),
          _ => 6.0,
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _status == _BackendEngineStatus.starting ? null : _handleTap,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment(alignX, alignY),
                    end: Alignment(-alignX, -alignY),
                    colors: const [
                      Color(0xFF8B5CF6),
                      Color(0xFF3B82F6),
                      Color(0xFF22D3EE),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withAlpha(_status == _BackendEngineStatus.starting
                          ? 180
                          : 140),
                      blurRadius: 24,
                      spreadRadius: spread,
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(1.5),
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0F),
                    borderRadius: BorderRadius.circular(12.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      iconWidget,
                      const SizedBox(width: 8),
                      Text(
                        buttonLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.2,
                          fontFamily: 'GeneralSans',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              statusLine,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mutedText,
                fontFamily: 'GeneralSans',
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Model selector row ────────────────────────────────────────────────────

class _ModelSelector extends StatelessWidget {
  const _ModelSelector({
    required this.depthLabel,
    required this.depthSublabel,
    required this.icon,
    required this.models,
    required this.selected,
    required this.onChanged,
  });

  final String depthLabel;
  final String depthSublabel;
  final IconData icon;
  final List<String> models;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    // Always offer "Server default" as the first option (null value).
    final items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem(
        value: null,
        child: Text('Server default',
            style: TextStyle(
                fontSize: 13,
                color: AppColors.mutedText,
                fontFamily: 'GeneralSans')),
      ),
      ...models.map((m) => DropdownMenuItem(
            value: m,
            child: Text(m,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryText,
                    fontFamily: 'GeneralSans'),
                overflow: TextOverflow.ellipsis),
          )),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 15, color: AppColors.secondaryText),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(depthLabel,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                      fontFamily: 'GeneralSans')),
              Text(depthSublabel,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedText,
                      fontFamily: 'GeneralSans')),
            ]),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderBright, width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: models.contains(selected) ? selected : null,
                isExpanded: true,
                dropdownColor: AppColors.surfaceElevated,
                icon: const Icon(Icons.unfold_more_rounded,
                    size: 16, color: AppColors.mutedText),
                items: items,
                onChanged: (v) => onChanged(v),
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryText,
                    fontFamily: 'GeneralSans'),
              ),
            ),
          ),
          // Chip showing the active selection
          if (selected != null && models.contains(selected)) ...[
            const SizedBox(height: 8),
            Row(children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: AppColors.success, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(selected!,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.success,
                        fontFamily: 'GeneralSans'),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

// ── Loading / error states ────────────────────────────────────────────────

class _ModelsLoadingState extends StatelessWidget {
  const _ModelsLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primaryText)),
        ),
        SizedBox(width: 12),
        Text('Loading available models…',
            style: TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
                fontFamily: 'GeneralSans')),
      ]),
    );
  }
}

class _ModelsErrorState extends StatelessWidget {
  const _ModelsErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withAlpha(60), width: 1),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.error_outline_rounded,
            size: 16, color: AppColors.error),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Could not load models',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.error,
                        fontFamily: 'GeneralSans')),
                const SizedBox(height: 4),
                Text(
                  message.contains('Connection')
                      ? 'Make sure the backend is running and the URL is correct, then press Connect.'
                      : message,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedText,
                      height: 1.4,
                      fontFamily: 'GeneralSans'),
                ),
              ]),
        ),
      ]),
    );
  }
}

// ── Status banner (connection test result) ────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.ok, required this.detail});
  final bool ok;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.success : AppColors.error;
    final icon = ok ? Icons.check_circle_outline_rounded : Icons.cancel_outlined;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(70), width: 1),
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(detail,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontFamily: 'GeneralSans')),
        ),
      ]),
    );
  }
}

class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard({
    required this.baseUrl,
    required this.isLoading,
    required this.isOk,
    required this.detail,
    required this.models,
    required this.onRefresh,
  });

  final String baseUrl;
  final bool isLoading;
  final bool? isOk;
  final String? detail;
  final List<String> models;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    const notChecked = 'Not checked';
    final statusText = isLoading
        ? 'Checking…'
        : (isOk == true ? 'Connected' : (isOk == false ? 'Not reachable' : notChecked));
    final statusColor = isLoading
        ? AppColors.secondaryText
        : (isOk == true ? AppColors.success : (isOk == false ? AppColors.error : AppColors.mutedText));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                  fontFamily: 'GeneralSans',
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: isLoading ? null : onRefresh,
                child: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Base URL: $baseUrl',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.secondaryText,
              fontFamily: 'GeneralSans',
            ),
          ),
          if (detail != null && detail!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              detail!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mutedText,
                height: 1.4,
                fontFamily: 'GeneralSans',
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            models.isEmpty
                ? 'Available models: none'
                : 'Available models: ${models.join(', ')}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.secondaryText,
              height: 1.4,
              fontFamily: 'GeneralSans',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pill button (Connect) ─────────────────────────────────────────────────

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.borderBright,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: AppColors.primaryText),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryText,
                  fontFamily: 'GeneralSans')),
        ]),
      ),
    );
  }
}

// ── Save button ───────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.onTap, required this.isLoading});
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isLoading ? AppColors.mutedText : AppColors.primaryText,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.background)))
              : const Text('Save Settings',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.background,
                      letterSpacing: 0.2,
                      fontFamily: 'GeneralSans')),
        ),
      ),
    );
  }
}