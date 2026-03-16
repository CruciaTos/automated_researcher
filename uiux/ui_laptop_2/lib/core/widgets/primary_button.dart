import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum PrimaryButtonVariant { filled, outlined, ghost }

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = PrimaryButtonVariant.filled,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final PrimaryButtonVariant variant;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => _controller.forward(),
      onTapUp: isDisabled ? null : (_) => _controller.reverse(),
      onTapCancel: isDisabled ? null : () => _controller.reverse(),
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          width: double.infinity,
          decoration: _decoration(isDisabled),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.background)))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon,
                            size: 16,
                            color: _fgColor(isDisabled)),
                        const SizedBox(width: 8),
                      ],
                      Text(widget.label,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              color: _fgColor(isDisabled),
                              fontFamily: 'GeneralSans')),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _decoration(bool disabled) {
    switch (widget.variant) {
      case PrimaryButtonVariant.filled:
        return BoxDecoration(
          color: disabled ? AppColors.mutedText : AppColors.primaryText,
          borderRadius: BorderRadius.circular(10),
        );
      case PrimaryButtonVariant.outlined:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: disabled ? AppColors.mutedText : AppColors.border,
              width: 1),
        );
      case PrimaryButtonVariant.ghost:
        return BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10));
    }
  }

  Color _fgColor(bool disabled) {
    switch (widget.variant) {
      case PrimaryButtonVariant.filled:
        return disabled
            ? AppColors.background.withAlpha(128)
            : AppColors.background;
      case PrimaryButtonVariant.outlined:
      case PrimaryButtonVariant.ghost:
        return disabled ? AppColors.mutedText : AppColors.primaryText;
    }
  }
}
