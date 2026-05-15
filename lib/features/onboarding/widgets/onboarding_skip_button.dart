import 'package:flutter/material.dart';

class OnboardingSkipButton extends StatelessWidget {
  const OnboardingSkipButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return TextButton(
      onPressed: onTap,
      child: Text(
        'Skip',
        style: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}
