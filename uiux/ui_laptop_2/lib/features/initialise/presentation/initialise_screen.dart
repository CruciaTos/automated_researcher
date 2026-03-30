import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

import '../../../core/providers/settings_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/advanced_settings_sheet.dart';

enum _InitialiseStatus { idle, starting, running, failed }

class InitialiseScreen extends ConsumerStatefulWidget {
  const InitialiseScreen({super.key});

  @override
  ConsumerState<InitialiseScreen> createState() => _InitialiseScreenState();
}

class _InitialiseScreenState extends ConsumerState<InitialiseScreen> {
  _InitialiseStatus _status = _InitialiseStatus.idle;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initHealthState();
  }

  Future<void> _initHealthState() async {
    final baseUrl = ref.read(backendUrlProvider);
    final isRunning = await _pingHealth(baseUrl);
    if (!mounted) return;
    setState(() {
      _status = isRunning ? _InitialiseStatus.running : _InitialiseStatus.idle;
    });
  }

  Future<bool> _pingHealth(String baseUrl) async {
    try {
      final healthUri = Uri.parse(baseUrl).resolve('/health');
      final response =
          await http.get(healthUri).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleTap(String baseUrl) async {
    if (_status == _InitialiseStatus.starting) return;
    if (_status == _InitialiseStatus.running) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backend is already running')),
      );
      return;
    }

    setState(() {
      _status = _InitialiseStatus.starting;
    });

    final healthyBeforeLaunch = await _pingHealth(baseUrl);
    if (healthyBeforeLaunch) {
      if (!mounted) return;
      setState(() {
        _status = _InitialiseStatus.running;
      });
      return;
    }

    if (!Platform.isWindows) {
      if (!mounted) return;
      setState(() {
        _status = _InitialiseStatus.failed;
      });
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
      final healthy = await _pingHealth(baseUrl);
      if (healthy) {
        if (!mounted) return;
        setState(() {
          _status = _InitialiseStatus.running;
        });
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _status = _InitialiseStatus.failed;
    });
  }

  bool get _isTappable => _status != _InitialiseStatus.starting;

  @override
  Widget build(BuildContext context) {
    final currentBaseUrl = ref.watch(backendUrlProvider);
    final borderColor = switch (_status) {
      _InitialiseStatus.running => AppColors.primaryText,
      _ => AppColors.borderBright,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryText,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.search_rounded,
                            color: AppColors.background,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Researcher',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                            letterSpacing: -0.3,
                            fontFamily: 'GeneralSans',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 64),
                    Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: _isTappable
                            ? (_) => setState(() => _isPressed = true)
                            : null,
                        onTapUp: _isTappable
                            ? (_) => setState(() => _isPressed = false)
                            : null,
                        onTapCancel: _isTappable
                            ? () => setState(() => _isPressed = false)
                            : null,
                        onTap:
                            _isTappable ? () => _handleTap(currentBaseUrl) : null,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 120),
                          scale: _isPressed ? 0.97 : 1,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surface,
                              border:
                                  Border.all(color: borderColor, width: 1.5),
                            ),
                            child: Center(child: _centerContent()),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _statusText(currentBaseUrl),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedText,
                        fontFamily: 'GeneralSans',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Expanded(child: SizedBox()),
            if (Platform.isWindows)
              GestureDetector(
                onTap: () => AdvancedSettingsSheet.show(context),
                child: const Text(
                  'Open Advanced Settings to change backend URL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedText,
                    fontFamily: 'GeneralSans',
                  ),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _statusText(String currentBaseUrl) {
    return switch (_status) {
      _InitialiseStatus.idle => 'Backend offline',
      _InitialiseStatus.starting => 'Starting backend...',
      _InitialiseStatus.running => 'Live at $currentBaseUrl',
      _InitialiseStatus.failed => 'Could not reach backend',
    };
  }

  Widget _centerContent() {
    return switch (_status) {
      _InitialiseStatus.idle => const Text(
          'IT\'S TIME\nBABY',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
            letterSpacing: -0.3,
            fontFamily: 'GeneralSans',
            height: 1.15,
          ),
        ),
      _InitialiseStatus.starting => const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryText),
          ),
        ),
      _InitialiseStatus.running => const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 28, color: AppColors.success),
            SizedBox(height: 4),
            Text(
              'Live',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.success,
                fontFamily: 'GeneralSans',
              ),
            ),
          ],
        ),
      _InitialiseStatus.failed => const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, size: 24, color: AppColors.primaryText),
            SizedBox(height: 4),
            Text(
              'Retry',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mutedText,
                fontFamily: 'GeneralSans',
              ),
            ),
          ],
        ),
    };
  }
}