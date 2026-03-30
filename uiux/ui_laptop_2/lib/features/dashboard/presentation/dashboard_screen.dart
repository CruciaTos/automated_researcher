import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:uiux/core/widgets/advanced_settings_sheet.dart';
import 'dart:math';

import '../../../core/providers/job_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final _topicCtrl = TextEditingController();
  final _focusNode = FocusNode();
  int _selectedDepth = 25;
  bool _isFocused = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;
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
    _DepthOption(
        minutes: 5,
        label: 'Quick',
        sublabel: '~5 min',
        icon: Icons.flash_on_rounded),
    _DepthOption(
        minutes: 25,
        label: 'Standard',
        sublabel: '~25 min',
        icon: Icons.search_rounded),
    _DepthOption(
        minutes: 40,
        label: 'Deep',
        sublabel: '~40 min',
        icon: Icons.travel_explore_rounded),
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
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _focusNode
        .addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    _focusNode.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creation = ref.watch(jobCreationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
            children: [
              // ── Header ───────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox.shrink(),
                    ],
                  ),
                  // ✅ Settings button — opens AdvancedSettingsSheet
                  GestureDetector(
                    onTap: () => AdvancedSettingsSheet.show(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: AppColors.border, width: 1)),
                      child: const Icon(Icons.tune_rounded,
                          size: 18, color: AppColors.secondaryText),
                    ),
                  ),
                ],
              ),
              Text('$_prompt, $_firstName',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                      letterSpacing: -0.6,
                      height: 1.1,
                      fontFamily: 'GeneralSans')),
              const SizedBox(height: 40),

              // ── Topic input ───────────────────────────────────────────────
              const Text('What should I research?',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryText,
                      letterSpacing: 0.3,
                      fontFamily: 'GeneralSans')),
              const SizedBox(height: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isFocused
                        ? AppColors.borderBright
                        : AppColors.border,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _topicCtrl,
                  focusNode: _focusNode,
                  maxLines: 4,
                  minLines: 4,
                  style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryText,
                      height: 1.5,
                      fontFamily: 'GeneralSans'),
                  decoration: const InputDecoration(
                    hintText:
                        'e.g. The impact of quantum computing on modern cryptography…',
                    hintStyle: TextStyle(
                        fontSize: 15,
                        color: AppColors.mutedText,
                        height: 1.5,
                        fontFamily: 'GeneralSans'),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.all(18),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Depth selector ────────────────────────────────────────────
              const Text('Research depth',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryText,
                      letterSpacing: 0.3,
                      fontFamily: 'GeneralSans')),
              const SizedBox(height: 10),
              Row(
                children: _depths.map((opt) {
                  final selected = _selectedDepth == opt.minutes;
                  return Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.only(right: opt.minutes != 40 ? 10 : 0),
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
              const SizedBox(height: 36),

              // ── Error banner ──────────────────────────────────────────────
              if (creation.hasError) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.error.withAlpha(76), width: 1),
                  ),
                  child: const Row(children: [
                    Icon(Icons.error_outline_rounded,
                        size: 16, color: AppColors.error),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          'Failed to start research. Check your backend URL in Advanced Settings.',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.error,
                              fontFamily: 'GeneralSans')),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              // ── Start button ──────────────────────────────────────────────
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
              const SizedBox(height: 40),

              // ── Example topics ────────────────────────────────────────────
              const Text('Example topics',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryText,
                      letterSpacing: 0.3,
                      fontFamily: 'GeneralSans')),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'AI safety regulation',
                  'Quantum cryptography',
                  'CRISPR gene editing ethics',
                  'Central bank digital currencies',
                  'Mars colonization challenges',
                ]
                    .map((t) => _ExampleChip(
                          label: t,
                          onTap: () {
                            _topicCtrl.text = t;
                            _focusNode.requestFocus();
                          },
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Supporting widgets ──────────────────────────────────────────────────────

class _DepthOption {
  const _DepthOption({
    required this.minutes,
    required this.label,
    required this.sublabel,
    required this.icon,
  });
  final int minutes;
  final String label;
  final String sublabel;
  final IconData icon;
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
        vsync: this, duration: const Duration(milliseconds: 150));
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
            color: widget.isSelected
                ? AppColors.primaryText
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.primaryText
                  : AppColors.border,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(widget.option.icon,
                  size: 20,
                  color: widget.isSelected
                      ? AppColors.background
                      : AppColors.secondaryText),
              const SizedBox(height: 8),
              Text(widget.option.label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.isSelected
                          ? AppColors.background
                          : AppColors.primaryText,
                      fontFamily: 'GeneralSans')),
              const SizedBox(height: 2),
              Text(widget.option.sublabel,
                  style: TextStyle(
                      fontSize: 11,
                      color: widget.isSelected
                          ? AppColors.background.withAlpha(153)
                          : AppColors.mutedText,
                      fontFamily: 'GeneralSans')),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  const _ExampleChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
                fontFamily: 'GeneralSans')),
      ),
    );
  }
}