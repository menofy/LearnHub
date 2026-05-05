import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'edu_primary_button.dart';

class ErrorRetryState extends StatelessWidget {
  const ErrorRetryState({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(AppColors.danger).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(AppColors.danger),
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface.withValues(alpha: 0.72),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: EduPrimaryButton(label: 'Try Again', onPressed: onRetry),
            ),
          ],
        ),
      ),
    );
  }
}
