import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class ContentLoadingSkeleton extends StatelessWidget {
  const ContentLoadingSkeleton({
    super.key,
    this.itemCount = 5,
    this.showHeader = true,
    this.tileHeight = 96,
  });

  final int itemCount;
  final bool showHeader;
  final double tileHeight;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        if (showHeader) ...[
          const _SkeletonBox(width: 120, height: 26),
          const SizedBox(height: 14),
          const _SkeletonBox(width: double.infinity, height: 50),
          const SizedBox(height: 14),
        ],
        ...List<Widget>.generate(
          itemCount,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index == itemCount - 1 ? 0 : 10),
            child: _SkeletonBox(
              width: double.infinity,
              height: tileHeight,
              borderRadius: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final alphaOffset = isDarkMode ? 0.06 : 0.08;
        final alpha =
            (isDarkMode ? 0.12 : 0.10) + (_controller.value * alphaOffset);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFFF3F7FF).withValues(alpha: alpha)
                : const Color(AppColors.dark).withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}
