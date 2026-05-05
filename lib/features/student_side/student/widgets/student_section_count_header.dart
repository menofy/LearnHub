import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class StudentSectionCountHeader extends StatelessWidget {
  const StudentSectionCountHeader({
    super.key,
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(AppColors.primary).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
