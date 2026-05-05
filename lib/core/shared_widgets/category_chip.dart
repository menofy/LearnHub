import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unselectedBg = isDark
        ? const Color(0xFF15243A)
        : const Color(AppColors.chip);
    final unselectedText = isDark
        ? Colors.white.withValues(alpha: 0.88)
        : const Color(AppColors.muted);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A8C7F) : unselectedBg,
          borderRadius: BorderRadius.circular(16),
          border: isDark && !isSelected
              ? Border.all(color: const Color(0xFF24324B))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : unselectedText,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
