import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SignupOtpCodeBoxes extends StatelessWidget {
  const SignupOtpCodeBoxes({
    super.key,
    required this.digits,
    this.length = 4,
  });

  final List<String> digits;
  final int length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(length, (index) {
        final isFilled = index < digits.length;
        final isNext = index == digits.length && digits.length < length;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 58,
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFilled || isNext
                  ? const Color(AppColors.primary)
                  : (isDark
                        ? colorScheme.outline.withValues(alpha: 0.7)
                        : const Color(AppColors.line)),
              width: isFilled || isNext ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              isFilled ? digits[index] : '',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        );
      }),
    );
  }
}
