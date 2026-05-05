import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SignupOtpResendSection extends StatelessWidget {
  const SignupOtpResendSection({
    super.key,
    required this.secondsRemaining,
    required this.onResend,
  });

  final int secondsRemaining;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final secondaryColor = colorScheme.onSurface.withValues(alpha: 0.68);
    final canResend = secondsRemaining == 0;

    return Column(
      children: [
        Text(
          canResend
              ? 'Didn\'t receive the code yet?'
              : 'You can request another code shortly.',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: secondaryColor,
          ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: canResend ? onResend : null,
          child: Text(
            canResend ? 'Resend code now' : 'Resend code in ${secondsRemaining}s',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: canResend
                  ? const Color(AppColors.primary)
                  : secondaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
