import 'package:flutter/material.dart';
import '../theme/desktop_theme.dart';

/// A metric card for the desktop dashboard grid.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.trend,
    this.trendPositive = true,
    this.accentColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? trend;
  final bool trendPositive;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? Dt.primary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: Dt.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 17, color: accent),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: trendPositive ? Dt.successBg : Dt.errorBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trend!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: trendPositive ? Dt.success : Dt.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(value, style: Dt.statValue),
          const SizedBox(height: 4),
          Text(label, style: Dt.bodySm),
        ],
      ),
    );
  }
}
