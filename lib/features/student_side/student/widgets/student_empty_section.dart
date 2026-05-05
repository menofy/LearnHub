import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class StudentEmptySection extends StatelessWidget {
  const StudentEmptySection({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? colorScheme.outline : const Color(AppColors.line),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}
