import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.border.withOpacity(_animation.value),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

class SkeletonResearchCard extends StatelessWidget {
  const SkeletonResearchCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: double.infinity, height: 16),
          const SizedBox(height: 8),
          SkeletonBox(width: MediaQuery.of(context).size.width * 0.6, height: 16),
          const SizedBox(height: 20),
          Row(
            children: [
              const SkeletonBox(width: 80, height: 24, borderRadius: 6),
              const Spacer(),
              const SkeletonBox(width: 60, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

class SkeletonReport extends StatelessWidget {
  const SkeletonReport({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonBox(width: double.infinity, height: 32, borderRadius: 8),
        const SizedBox(height: 8),
        SkeletonBox(
            width: MediaQuery.of(context).size.width * 0.5,
            height: 20,
            borderRadius: 6),
        const SizedBox(height: 32),
        ...List.generate(
          5,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SkeletonBox(
              width: i % 3 == 2
                  ? MediaQuery.of(context).size.width * 0.8
                  : double.infinity,
              height: 14,
              borderRadius: 4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SkeletonBox(
              width: i == 3
                  ? MediaQuery.of(context).size.width * 0.6
                  : double.infinity,
              height: 14,
              borderRadius: 4,
            ),
          ),
        ),
      ],
    );
  }
}
