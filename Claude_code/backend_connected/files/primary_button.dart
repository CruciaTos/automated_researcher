import 'package:flutter/material.dart';
import '../theme/desktop_theme.dart';

/// A reusable filled primary button styled with [Dt.primary].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.height = 40.0,
  });

  final String       label;
  final VoidCallback? onPressed;
  final IconData?    icon;
  final bool         loading;
  final double       height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width:  16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : (icon != null
                ? Icon(icon, size: 16)
                : const SizedBox.shrink()),
        label: Text(
          loading ? 'Please wait…' : label,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Dt.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Dt.primary.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dt.inputRadius),
          ),
        ),
      ),
    );
  }
}
