import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class OnboardingSkipButton extends StatelessWidget {
  const OnboardingSkipButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: const Text(
        'Skip',
        style: TextStyle(
          color: Color(AppColors.dark),
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}
