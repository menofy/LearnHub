import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class EduSearchField extends StatelessWidget {
  const EduSearchField({
    super.key,
    this.hint = 'Search for ..',
    this.controller,
    this.onChanged,
    this.onFilterTap,
    this.readOnly = false,
    this.onTap,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF101A2D) : Colors.white;
    final iconColor = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : const Color(AppColors.dark);
    final hintColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : const Color(AppColors.muted);

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(13),
        border: isDark ? Border.all(color: const Color(0xFF24324B)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: iconColor, size: 21),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              readOnly: readOnly,
              onTap: onTap,
              decoration: InputDecoration(
                hintText: hint,
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: hintColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(AppColors.primary),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
