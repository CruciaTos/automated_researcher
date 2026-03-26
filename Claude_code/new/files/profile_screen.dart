import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/providers/settings_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../settings/presentation/advanced_settings_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final backendUrl = ref.watch(backendUrlProvider);
    final modelPrefs = ref.watch(modelPreferencesProvider);

    final displayName = authState.maybeWhen(
      data: (user) => user?.displayName ?? user?.email ?? 'Researcher',
      orElse: () => 'Researcher',
    );
    final email = authState.maybeWhen(
      data: (user) => user?.email ?? '',
      orElse: () => '',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              const Text('Profile',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                      letterSpacing: -0.8,
                      fontFamily: 'GeneralSans')),
              const SizedBox(height: 32),

              // ── User card ─────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1)),
                child: Row(children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.person_rounded,
                        size: 24, color: AppColors.secondaryText),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                                fontFamily: 'GeneralSans')),
                        const SizedBox(height: 2),
                        Text(email,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.mutedText,
                                fontFamily: 'GeneralSans'),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 28),

              // ── Backend status card ───────────────────────────────────────
              GestureDetector(
                onTap: () => AdvancedSettingsSheet.show(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 1)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.dns_outlined,
                              size: 16, color: AppColors.secondaryText),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Backend Connection',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryText,
                                  fontFamily: 'GeneralSans')),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            size: 16, color: AppColors.mutedText),
                      ]),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(backendUrl,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.mutedText,
                                fontFamily: 'GeneralSans'),
                            overflow: TextOverflow.ellipsis),
                      ),
                      // Show active models if any are set
                      if (modelPrefs.basic != null ||
                          modelPrefs.standard != null ||
                          modelPrefs.deep != null) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (modelPrefs.basic != null)
                              _ModelBadge(
                                  label: 'Quick',
                                  model: modelPrefs.basic!),
                            if (modelPrefs.standard != null)
                              _ModelBadge(
                                  label: 'Standard',
                                  model: modelPrefs.standard!),
                            if (modelPrefs.deep != null)
                              _ModelBadge(
                                  label: 'Deep',
                                  model: modelPrefs.deep!),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Advanced Settings button ───────────────────────────────────
              GestureDetector(
                onTap: () => AdvancedSettingsSheet.show(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1)),
                  child: const Row(children: [
                    Icon(Icons.tune_rounded,
                        size: 18, color: AppColors.secondaryText),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('Advanced Settings',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primaryText,
                              fontFamily: 'GeneralSans')),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColors.mutedText),
                  ]),
                ),
              ),
              const SizedBox(height: 28),

              // ── Preferences ───────────────────────────────────────────────
              _SectionHeader(label: 'Preferences'),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                label: 'Email updates',
                trailing: Switch.adaptive(
                    value: true,
                    onChanged: (_) {},
                    activeColor: AppColors.primaryText),
              ),
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                label: 'Dark mode',
                trailing: Switch.adaptive(
                    value: true,
                    onChanged: (_) {},
                    activeColor: AppColors.primaryText),
              ),
              const SizedBox(height: 20),

              // ── About ─────────────────────────────────────────────────────
              _SectionHeader(label: 'About'),
              const SizedBox(height: 12),
              const _SettingsTile(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                trailing: Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.mutedText),
              ),
              const _SettingsTile(
                icon: Icons.shield_outlined,
                label: 'Privacy Policy',
                trailing: Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.mutedText),
              ),
              const SizedBox(height: 32),

              // ── Sign out ──────────────────────────────────────────────────
              PrimaryButton(
                label: 'Sign out',
                variant: PrimaryButtonVariant.outlined,
                onPressed: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go('/login');
                },
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('Researcher v1.0.0',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedText,
                        fontFamily: 'GeneralSans')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModelBadge extends StatelessWidget {
  const _ModelBadge({required this.label, required this.model});
  final String label;
  final String model;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.success.withAlpha(60), width: 1),
      ),
      child: Text('$label: $model',
          style: const TextStyle(
              fontSize: 10,
              color: AppColors.success,
              fontFamily: 'GeneralSans'),
          overflow: TextOverflow.ellipsis),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(label.toUpperCase(),
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.mutedText,
          letterSpacing: 0.8,
          fontFamily: 'GeneralSans'));
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.trailing,
  });
  final IconData icon;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1)),
      child: ListTile(
        leading: Icon(icon, size: 18, color: AppColors.secondaryText),
        title: Text(label,
            style: const TextStyle(
                fontSize: 14,
                color: AppColors.primaryText,
                fontFamily: 'GeneralSans')),
        trailing: trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        dense: true,
      ),
    );
  }
}
