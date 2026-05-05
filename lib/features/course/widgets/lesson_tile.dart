import 'package:flutter/material.dart';
import 'package:learnhub/core/theme/app_colors.dart';
import 'package:learnhub/domain/entities/lesson.dart';

class LessonTile extends StatelessWidget {
  const LessonTile({super.key, required this.lesson, required this.onTap});

  final Lesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isDark
              ? Border.all(color: colorScheme.outline.withValues(alpha: 0.85))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF15243A)
                    : const Color(AppColors.bg),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 18,
                  color: Color(AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lesson.duration,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.72),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.play_circle_fill_rounded,
              color: Color(AppColors.primary),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
