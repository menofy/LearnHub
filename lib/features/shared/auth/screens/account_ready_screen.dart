import 'package:flutter/material.dart';
import 'package:learnhub/core/navigation/app_routes.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';

class AccountReadyScreen extends StatelessWidget {
  const AccountReadyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4B4E74),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
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
                      Icons.verified_user_rounded,
                      size: 86,
                      color: Color(0xFFFFC107),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Congratulations',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your Account is Ready to Use. You will be\nredirected to the Home Page in a Few\nSeconds.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6E7790),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    EduPrimaryButton(
                      label: 'Continue',
                      onPressed: () =>
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.root,
                            (route) => false,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
