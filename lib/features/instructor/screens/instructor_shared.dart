import 'package:flutter/material.dart';

import 'package:learnhub/core/theme/app_colors.dart';
import '../../../domain/entities/course.dart';

const List<String> instructorCategories = <String>[
  'Flutter',
  'Programming',
  'Design',
  'Backend',
  'Computer Science',
  'Testing',
  'Product',
];

String instructorFormatDate(DateTime? date) {
  if (date == null) {
    return 'Just now';
  }

  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String instructorCourseSourceLabel(Course course) {
  if (course.usesUploadedVideos) {
    return 'Uploads';
  }
  if (course.playlistId.trim().isNotEmpty) {
    return 'Playlist';
  }
  final url = course.primaryPlayableVideoUrl.toLowerCase();
  if (url.contains('youtube.com') || url.contains('youtu.be')) {
    return 'YouTube';
  }
  return 'External';
}

bool instructorIsDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color instructorTitleColor(BuildContext context) =>
    Theme.of(context).colorScheme.onSurface;

Color instructorMutedColor(BuildContext context) =>
    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72);

Color instructorBorderColor(BuildContext context) => instructorIsDark(context)
    ? Theme.of(context).colorScheme.outline
    : const Color(AppColors.line);

Color instructorSurfaceColor(BuildContext context) => instructorIsDark(context)
    ? Theme.of(context).colorScheme.surface
    : Colors.white;

Color instructorInsetColor(BuildContext context) => instructorIsDark(context)
    ? const Color(0xFF111E34)
    : const Color(0xFFF5F8FD);

InputDecoration instructorInputDecoration({
  required BuildContext context,
  required String label,
  required String hint,
  required IconData icon,
  String? helperText,
  Widget? suffixIcon,
}) {
  final mutedColor = instructorMutedColor(context);
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: mutedColor,
    ),
    hintStyle: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: mutedColor.withValues(alpha: 0.88),
    ),
    helperStyle: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: mutedColor,
    ),
    helperText: helperText,
    prefixIcon: Icon(icon, size: 20, color: mutedColor),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: instructorInsetColor(context),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: instructorBorderColor(context)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: instructorBorderColor(context)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(AppColors.primary), width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(AppColors.danger), width: 1.1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(AppColors.danger), width: 1.4),
    ),
  );
}

class InstructorSurfaceCard extends StatelessWidget {
  const InstructorSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = instructorIsDark(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: instructorSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: instructorBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class InstructorSectionHeader extends StatelessWidget {
  const InstructorSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: instructorTitleColor(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: instructorMutedColor(context),
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }
}

class InstructorMetricCard extends StatelessWidget {
  const InstructorMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor = const Color(AppColors.primary),
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return InstructorSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: instructorTitleColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: instructorMutedColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class InstructorPill extends StatelessWidget {
  const InstructorPill({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final chipBackground =
        backgroundColor ??
        (instructorIsDark(context)
            ? const Color(0xFF15243A)
            : const Color(0xFFEAF8F7));
    final chipForeground = foregroundColor ?? const Color(AppColors.primary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: chipBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: chipForeground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: chipForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class InstructorEmptyState extends StatelessWidget {
  const InstructorEmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return InstructorSurfaceCard(
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(AppColors.primary).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: const Color(AppColors.primary)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: instructorTitleColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.55,
              fontWeight: FontWeight.w700,
              color: instructorMutedColor(context),
            ),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}
