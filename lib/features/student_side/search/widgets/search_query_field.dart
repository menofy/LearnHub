import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SearchQueryField extends StatelessWidget {
  const SearchQueryField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onActionTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final secondaryText = colorScheme.onSurface.withValues(alpha: 0.72);

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: isDark
            ? Border.all(color: colorScheme.outline.withValues(alpha: 0.85))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 21, color: secondaryText),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Graphic Design',
                filled: false,
                contentPadding: EdgeInsets.zero,
                hintStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: secondaryText,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onActionTap,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(AppColors.primary),
              ),
              child: const Icon(
                Icons.search_rounded,
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
