import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                  letterSpacing: -0.8,
                  fontFamily: 'GeneralSans',
                ),
              ),
              const SizedBox(height: 32),

              // Avatar + info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 24,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Researcher',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                            fontFamily: 'GeneralSans',
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'user@example.com',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedText,
                            fontFamily: 'GeneralSans',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Settings
              _SectionHeader(label: 'Preferences'),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                label: 'Email updates',
                trailing: Switch.adaptive(
                  value: true,
                  onChanged: (_) {},
                  activeColor: AppColors.primaryText,
                ),
              ),
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                label: 'Dark mode',
                trailing: Switch.adaptive(
                  value: true,
                  onChanged: (_) {},
                  activeColor: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 20),

              _SectionHeader(label: 'About'),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.mutedText,
                ),
              ),
              _SettingsTile(
                icon: Icons.shield_outlined,
                label: 'Privacy Policy',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.mutedText,
                ),
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                label: 'Terms of Service',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 32),

              PrimaryButton(
                label: 'Sign out',
                variant: PrimaryButtonVariant.outlined,
                onPressed: () => context.go('/login'),
              ),

              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Researcher v1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedText,
                    fontFamily: 'GeneralSans',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.mutedText,
        letterSpacing: 0.8,
        fontFamily: 'GeneralSans',
      ),
    );
  }
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
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: ListTile(
        leading: Icon(icon, size: 18, color: AppColors.secondaryText),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.primaryText,
            fontFamily: 'GeneralSans',
          ),
        ),
        trailing: trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        dense: true,
      ),
    );
  }
}
