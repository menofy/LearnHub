import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AuthSwitchPrompt extends StatelessWidget {
  const AuthSwitchPrompt({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.secondaryColor,
    required this.onTap,
  });

  final String prompt;
  final String actionLabel;
  final Color secondaryColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          prompt,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: secondaryColor,
          ),
        ),
        InkWell(
          onTap: onTap,
          child: Text(
            actionLabel,
            style: const TextStyle(
              color: Color(AppColors.primary),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
