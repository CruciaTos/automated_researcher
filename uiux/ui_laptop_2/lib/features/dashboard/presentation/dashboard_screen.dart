import 'dart:io';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:uiux/core/widgets/advanced_settings_sheet.dart';

import '../../../core/providers/job_providers.dart';
import '../../../core/providers/settings_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';

enum _InitStatus { idle, starting, running, failed }

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  final _topicCtrl = TextEditingController();
  final _focusNode = FocusNode();
  int _selectedDepth = 25;
  bool _isFocused = false;

  _InitStatus _backendStatus = _InitStatus.idle;
  bool _buttonPressed = false;

  late final AnimationController _heartbeatCtrl;
  late final AnimationController _contentCtrl;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  late final String _prompt;
  late final String _firstName;

  static const _prompts = [
    "Let's work nightout",
    'Time to go deep',
    'What are we solving today',
    "Let's find some answers",
    'Ready when you are',
    'Knowledge incoming',
    "Let's get to work",
  ];

  static const _depths = [
    _DepthOption(minutes: 5, label: 'Quick', sublabel: '~5 min'),
    _DepthOption(minutes: 25, label: 'Standard', sublabel: '~25 min'),
    _DepthOption(minutes: 40, label: 'Deep', sublabel: '~40 min'),
  ];

  @override
  void initState() {
    super.initState();
    _prompt = _prompts[Random().nextInt(_prompts.length)];
    final user = FirebaseAuth.instance.currentUser;
    final display = user?.displayName?.trim();
    _firstName = (display != null && display.isNotEmpty)
        ? display.split(' ').first
        : (user?.email?.split('@').first ?? 'Researcher');

    _focusNode
        .addListener(() => setState(() => _isFocused = _focusNode.hasFocus));

    _heartbeatCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _contentCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic));

    _initBackendCheck();
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    _focusNode.dispose();
    _heartbeatCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _initBackendCheck() async {
    final url = ref.read(backendUrlProvider);
    final ok = await _ping(url);
    if (!mounted) return;
    setState(() => _backendStatus = ok ? _InitStatus.running : _InitStatus.idle);
    if (ok) _contentCtrl.forward();
  }

  Future<bool> _ping(String url) async {
    try {
      final r = await http
          .get(Uri.parse(url).resolve('/health'))
          .timeout(const Duration(seconds: 4));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleEngineButton() async {
    if (_backendStatus == _InitStatus.starting) return;

    setState(() => _buttonPressed = true);
    _heartbeatCtrl.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (mounted) {
      setState(() => _buttonPressed = false);
    }

    if (_backendStatus == _InitStatus.running) {
      if (!mounted) return;
      setState(() {
        _backendStatus = _InitStatus.idle;
        _contentCtrl.reverse();
      });
      return;
    }

    setState(() => _backendStatus = _InitStatus.starting);

    final url = ref.read(backendUrlProvider);

    if (await _ping(url)) {
      _setRunning();
      return;
    }

    if (Platform.isWindows) {
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
        if (await _ping(url)) {
          _setRunning();
          return;
        }
      }
    }

    if (mounted) {
      setState(() => _backendStatus = _InitStatus.failed);
    }
  }

  void _setRunning() {
    if (!mounted) return;
    setState(() => _backendStatus = _InitStatus.running);
    _contentCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final creation = ref.watch(jobCreationProvider);
    final isRunning = _backendStatus == _InitStatus.running;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            if (!isRunning)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_prompt, $_firstName',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                        letterSpacing: -1,
                        fontFamily: 'GeneralSans',
                      ),
                    ),
                    const SizedBox(height: 32),
                    ScaleTransition(
                      scale: Tween<double>(begin: 1, end: 0.98).animate(
                        CurvedAnimation(parent: _heartbeatCtrl, curve: Curves.easeOut),
                      ),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 120),
                        scale: _buttonPressed ? 0.97 : 1,
                        child: _HeartbeatButton(
                          status: _backendStatus,
                          onTap: _handleEngineButton,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _backendStatus == _InitStatus.idle
                          ? 'Backend offline'
                          : _backendStatus == _InitStatus.starting
                              ? 'Starting backend...'
                              : 'Could not reach backend — tap to retry',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText,
                        fontFamily: 'GeneralSans',
                      ),
                    ),
                  ],
                ),
              ),
            if (isRunning)
              FadeTransition(
                opacity: _contentFade,
                child: SlideTransition(
                  position: _contentSlide,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_prompt, $_firstName',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                              letterSpacing: -1,
                              fontFamily: 'GeneralSans',
                            ),
                          ),
                          const SizedBox(height: 28),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _isFocused
                                    ? AppColors.borderBright
                                    : AppColors.border,
                              ),
                            ),
                            child: TextField(
                              controller: _topicCtrl,
                              focusNode: _focusNode,
                              maxLines: 4,
                              minLines: 4,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.primaryText,
                                height: 1.5,
                                fontFamily: 'GeneralSans',
                              ),
                              decoration: const InputDecoration(
                                hintText: 'What should I research?',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.mutedText,
                                  fontFamily: 'GeneralSans',
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: _depths.map((opt) {
                              final selected = _selectedDepth == opt.minutes;
                              return Expanded(
                                child: Padding(
                                  padding:
                                      EdgeInsets.only(right: opt.minutes != 40 ? 8 : 0),
                                  child: _DepthCard(
                                    option: opt,
                                    isSelected: selected,
                                    onTap: () =>
                                        setState(() => _selectedDepth = opt.minutes),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          PrimaryButton(
                            label: 'Start Research',
                            isLoading: creation.isLoading,
                            onPressed: () async {
                              final topic = _topicCtrl.text.trim();
                              if (topic.isEmpty) return;

                              _focusNode.unfocus();

                              await ref
                                  .read(jobCreationProvider.notifier)
                                  .createJob(topic, _selectedDepth);

                              final job = ref.read(jobCreationProvider).value;

                              if (job != null && context.mounted) {
                                ref.read(jobCreationProvider.notifier).reset();
                                context.go('/jobs/${job.id}/progress');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (!isRunning)
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () => AdvancedSettingsSheet.show(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DepthOption {
  const _DepthOption({
    required this.minutes,
    required this.label,
    required this.sublabel,
  });

  final int minutes;
  final String label;
  final String sublabel;
}

class _DepthCard extends StatefulWidget {
  const _DepthCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _DepthOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_DepthCard> createState() => _DepthCardState();
}

class _DepthCardState extends State<_DepthCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) =>
            Transform.scale(scale: 1.0 - _ctrl.value * 0.03, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: widget.isSelected ? const Color(0xFF1E1E1E) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected ? AppColors.borderBright : AppColors.border,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                widget.option.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      widget.isSelected ? AppColors.primaryText : AppColors.primaryText,
                  fontFamily: 'GeneralSans',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.option.sublabel,
                style: TextStyle(
                  fontSize: 11,
                  color: widget.isSelected
                      ? AppColors.secondaryText
                      : AppColors.mutedText,
                  fontFamily: 'GeneralSans',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeartbeatButton extends StatelessWidget {
  const _HeartbeatButton({
    required this.status,
    required this.onTap,
  });

  final _InitStatus status;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final isStarting = status == _InitStatus.starting;
    final isRunning = status == _InitStatus.running;

    return GestureDetector(
      onTap: isStarting ? null : () => onTap(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(
            width: 1.5,
            color: isRunning ? AppColors.primaryText : AppColors.borderBright,
          ),
        ),
        child: Center(
          child: switch (status) {
            _InitStatus.idle => const Text(
                'START\nENGINE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                  letterSpacing: -0.3,
                  fontFamily: 'GeneralSans',
                ),
              ),
            _InitStatus.starting => const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryText),
                ),
              ),
            _InitStatus.running => const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GreenDot(),
                  SizedBox(height: 6),
                  Text(
                    'ONLINE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                      fontFamily: 'GeneralSans',
                    ),
                  ),
                ],
              ),
            _InitStatus.failed => const Column(
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
          },
        ),
      ),
    );
  }
}

class _GreenDot extends StatelessWidget {
  const _GreenDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: const BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
      ),
    );
  }
}