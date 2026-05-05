import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Tab Navigation
class InstructorTabNavigation extends StatelessWidget {
  const InstructorTabNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  final int selectedIndex;
  final Function(int) onTabChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final inactiveColor = colorScheme.onSurface.withValues(alpha: 0.62);

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onTabChanged(0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selectedIndex == 0
                        ? const Color(AppColors.primary)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                'Courses',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: selectedIndex == 0
                      ? const Color(AppColors.primary)
                      : inactiveColor,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onTabChanged(1),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selectedIndex == 1
                        ? const Color(AppColors.primary)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                'Ratings',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: selectedIndex == 1
                      ? const Color(AppColors.primary)
                      : inactiveColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
