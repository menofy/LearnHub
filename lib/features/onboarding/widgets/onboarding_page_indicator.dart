import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
  });

  final int pageCount;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(pageCount, (index) {
        final isSelected = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 12 : 6,
          height: 6,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(AppColors.primary)
                : const Color(0xFFD4E2F3),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
