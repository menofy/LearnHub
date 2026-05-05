import 'package:flutter/material.dart';
import 'package:learnhub/features/instructor/screens/instructor_shared.dart';

import '../../../../core/theme/app_colors.dart';

class MyCourseSummaryTile extends StatelessWidget {
  const MyCourseSummaryTile({
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
    final titleColor = instructorTitleColor(context);
    final secondaryText = instructorMutedColor(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accentColor),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
