import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/desktop_providers.dart';
import '../../../core/theme/desktop_theme.dart';
import '../../../core/widgets/desktop_card.dart';

class DesktopSettingsScreen extends ConsumerStatefulWidget {
  const DesktopSettingsScreen({super.key});

  @override
  ConsumerState<DesktopSettingsScreen> createState() =>
      _DesktopSettingsScreenState();
}

class _DesktopSettingsScreenState
    extends ConsumerState<DesktopSettingsScreen> {
  final _backendCtrl =
      TextEditingController(text: 'http://localhost:8000');
  final _ollamaCtrl  =
      TextEditingController(text: 'http://localhost:11434');
  String _modelName  = 'qwen2.5:7b';
  bool   _emailUpdates = true;
  bool   _autoCleanup  = true;

  @override
  void dispose() {
    _backendCtrl.dispose();
    _ollamaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final healthAsync = ref.watch(backendHealthProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dt.contentPadH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings', style: Dt.pageTitle),
          const SizedBox(height: 4),
          const Text('Configure your research workspace.',
              style: Dt.bodyMd),
          const SizedBox(height: 28),

          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: _leftColumn(healthAsync)),
                    const SizedBox(width: 20),
                    Expanded(child: _rightColumn()),
                  ],
                );
              }
              return Column(
                children: [
                  _leftColumn(healthAsync),
                  const SizedBox(height: 20),
                  _rightColumn(),
                ],
              );
            },
          ),

          const SizedBox(height: 28),
          Row(
            children: [
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon:  const Icon(Icons.save_outlined,
                      size: 15),
                  label: const Text('Save Settings',
                      style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Dt.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          Dt.inputRadius),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(backendHealthProvider),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Dt.textSecondary,
                    side: const BorderSide(
                        color: Dt.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          Dt.inputRadius),
                    ),
                  ),
                  child: const Text('Test Connection',
                      style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _leftColumn(AsyncValue<bool> healthAsync) =>
      Column(
        children: [
          DesktopCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardHeader(
                  icon:     Icons.dns_outlined,
                  color:    Dt.info,
                  title:    'Backend',
                  trailing: healthAsync.when(
                    data: (ok) =>
                        _StatusDot(connected: ok),
                    loading: () =>
                        const _StatusDot(connected: null),
                    error: (_, __) =>
                        const _StatusDot(connected: false),
                  ),
                ),
                const SizedBox(height: 16),
                _LabeledInput(
                  label:      'Backend URL',
                  controller: _backendCtrl,
                  hint:       'http://localhost:8000',
                ),
                const SizedBox(height: 12),
                _LabeledInput(
                  label:      'Ollama API URL',
                  controller: _ollamaCtrl,
                  hint:       'http://localhost:11434',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DesktopCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardHeader(
                  icon:  Icons.smart_toy_outlined,
                  color: Dt.primary,
                  title: 'Language Model',
                ),
                const SizedBox(height: 16),
                const Text('Active model', style: Dt.bodyMd),
                const SizedBox(height: 6),
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12),
                  decoration: BoxDecoration(
                    color: Dt.bgInput,
                    borderRadius:
                        BorderRadius.circular(Dt.inputRadius),
                    border: Border.all(color: Dt.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value:      _modelName,
                      isExpanded: true,
                      style: const TextStyle(
                          fontSize: 13,
                          color:    Dt.textPrimary),
                      icon: const Icon(
                          Icons.expand_more_rounded,
                          size:  16,
                          color: Dt.textMuted),
                      items: const [
                        DropdownMenuItem(
                            value: 'qwen2.5:7b',
                            child: Text('Qwen 2.5 7B')),
                        DropdownMenuItem(
                            value: 'llama3.2:3b',
                            child: Text('Llama 3.2 3B')),
                        DropdownMenuItem(
                            value: 'mistral:7b',
                            child: Text('Mistral 7B')),
                      ],
                      onChanged: (v) => setState(
                          () => _modelName =
                              v ?? _modelName),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Dt.bgMuted,
                    borderRadius:
                        BorderRadius.circular(Dt.inputRadius),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 14, color: Dt.textMuted),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Models are served locally via Ollama. '
                          'Ensure the model is pulled before starting.',
                          style: TextStyle(
                              fontSize: 11,
                              color:    Dt.textMuted,
                              height:   1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _rightColumn() => Column(
        children: [
          DesktopCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardHeader(
                  icon:  Icons.tune_outlined,
                  color: Dt.warning,
                  title: 'Preferences',
                ),
                const SizedBox(height: 14),
                _SwitchRow(
                  label:    'Email job completion updates',
                  value:    _emailUpdates,
                  onChange: (v) =>
                      setState(() => _emailUpdates = v),
                ),
                _SwitchRow(
                  label: 'Auto-delete jobs older than 3 days',
                  value: _autoCleanup,
                  onChange: (v) =>
                      setState(() => _autoCleanup = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DesktopCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardHeader(
                  icon:  Icons.info_outline_rounded,
                  color: Dt.textMuted,
                  title: 'About',
                ),
                const SizedBox(height: 14),
                _InfoRow('Version',  '1.0.0'),
                _InfoRow('Backend',  'FastAPI + SQLite'),
                _InfoRow('Embedder', 'bge-small-en-v1.5'),
                _InfoRow('Vector DB', 'FAISS'),
                _InfoRow('Sources',  'Wikipedia, arXiv'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DesktopCard(
            color: Dt.errorBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 16, color: Dt.error),
                    SizedBox(width: 8),
                    Text('Danger Zone',
                        style: TextStyle(
                            fontSize:   14,
                            fontWeight: FontWeight.w600,
                            color:      Dt.error)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'These actions are irreversible. Proceed with caution.',
                  style:
                      TextStyle(fontSize: 12, color: Dt.error),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 34,
                  child: OutlinedButton(
                    onPressed: () {/* TODO: clear all jobs */},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Dt.error,
                      side: BorderSide(
                          color: Dt.error.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            Dt.inputRadius),
                      ),
                    ),
                    child: const Text(
                        'Clear All Jobs & Reports',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Settings saved'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Dt.textPrimary,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(Dt.inputRadius)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.icon,
    required this.color,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final Color    color;
  final String   title;
  final Widget?  trailing;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width:  28,
            height: 28,
            decoration: BoxDecoration(
              color:  color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Text(title, style: Dt.cardTitle),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      );
}

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({
    required this.label,
    required this.controller,
    required this.hint,
  });

  final String               label;
  final TextEditingController controller;
  final String               hint;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Dt.bodyMd),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText:  hint,
                hintStyle: const TextStyle(
                    fontSize: 13, color: Dt.textMuted),
                contentPadding:
                    const EdgeInsets.symmetric(
                        horizontal: 12),
                isDense:   true,
                filled:    true,
                fillColor: Dt.bgInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      Dt.inputRadius),
                  borderSide: const BorderSide(
                      color: Dt.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      Dt.inputRadius),
                  borderSide: const BorderSide(
                      color: Dt.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      Dt.inputRadius),
                  borderSide: const BorderSide(
                      color: Dt.borderFocus, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChange,
  });

  final String             label;
  final bool               value;
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: Dt.bodyMd)),
            Switch(
              value:       value,
              onChanged:   onChange,
              activeColor: Dt.primary,
              materialTapTargetSize:
                  MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
                width: 90,
                child: Text(label, style: Dt.bodySm)),
            Text(value,
                style: const TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w500,
                    color:      Dt.textPrimary)),
          ],
        ),
      );
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({this.connected});
  final bool? connected;

  @override
  Widget build(BuildContext context) {
    Color  color;
    String label;
    if (connected == null) {
      color = Dt.textMuted; label = 'Checking';
    } else if (connected!) {
      color = Dt.success;   label = 'Online';
    } else {
      color = Dt.error;     label = 'Offline';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width:  7,
          height: 7,
          decoration: BoxDecoration(
              color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color:      color)),
      ],
    );
  }
}
