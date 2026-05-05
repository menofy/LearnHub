import 'package:flutter/material.dart';

/// Statistics item
class InstructorStatItem extends StatelessWidget {
  const InstructorStatItem({
    super.key,
    required this.value,
    required this.label,
    this.onTap,
  });

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleColor = colorScheme.onSurface;
    final subtitleColor = colorScheme.onSurface.withValues(alpha: 0.62);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}
