import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';

import 'package:learnhub/core/navigation/app_routes.dart';

class ResetPasswordSuccessScreen extends StatelessWidget {
  const ResetPasswordSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4B4E74),
      body: SafeArea(
        child: Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.security_rounded,
                  size: 86,
                  color: Color(0xFF90A4B9),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Congratulations',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your Password has been updated\nsuccessfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6E7790),
                  ),
                ),
                const SizedBox(height: 16),
                EduPrimaryButton(
                  label: 'Back to Login',
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
