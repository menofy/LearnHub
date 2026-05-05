import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class LearningScreenHeader extends StatelessWidget {
  const LearningScreenHeader({
    super.key,
    required this.showCompleted,
    required this.onSearchTap,
    required this.onCompletedTap,
    required this.onOngoingTap,
  });

  final bool showCompleted;
  final VoidCallback onSearchTap;
  final VoidCallback onCompletedTap;
  final VoidCallback onOngoingTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final secondaryText = colorScheme.onSurface.withValues(alpha: 0.72);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'My Courses',
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
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
              Expanded(
                child: Text(
                  'Search for ...',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onSearchTap,
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
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF15243A)
                : const Color(AppColors.chip),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: _LearningTabPill(
                  label: 'Completed',
                  active: showCompleted,
                  onTap: onCompletedTap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LearningTabPill(
                  label: 'Ongoing',
                  active: !showCompleted,
                  onTap: onOngoingTap,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LearningTabPill extends StatelessWidget {
  const _LearningTabPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1A8C7F) : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
