import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/learnhub_logo_mark.dart';

import '../../../../core/theme/app_colors.dart';

class LoginIntroSection extends StatelessWidget {
  const LoginIntroSection({
    super.key,
    required this.isLoading,
    required this.titleColor,
    required this.secondaryColor,
  });

  final bool isLoading;
  final Color titleColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isLoading) ...[
          const LinearProgressIndicator(
            minHeight: 3,
            color: Color(AppColors.primary),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 25),
        const Center(child: LearnHubLogoMark(size: 88)),
        const SizedBox(height: 60),
        Text(
          'Let\'s Sign In.!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Login to your account to continue your courses',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: secondaryColor,
          ),
        ),
      ],
    );
  }
}
