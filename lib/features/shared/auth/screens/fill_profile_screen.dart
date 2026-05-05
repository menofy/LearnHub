import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';

import 'package:learnhub/core/navigation/app_routes.dart';
import 'package:learnhub/core/theme/app_colors.dart';

class FillProfileScreen extends StatelessWidget {
  const FillProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fill Your Profile',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(42),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 46,
                      color: Color(0xFFC7D4E8),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(AppColors.primary),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const _Field(hint: 'Full Name'),
            const SizedBox(height: 10),
            const _Field(hint: 'Nick Name'),
            const SizedBox(height: 10),
            const _Field(
              hint: 'Date of Birth',
              icon: Icons.calendar_today_outlined,
            ),
            const SizedBox(height: 10),
            const _Field(hint: 'Email', icon: Icons.email_outlined),
            const SizedBox(height: 10),
            const _Field(hint: '(+20) 1145-9455-22'),
            const SizedBox(height: 10),
            const _Field(
              hint: 'Gender',
              suffix: Icons.keyboard_arrow_down_rounded,
            ),
            const SizedBox(height: 20),
            EduPrimaryButton(
              label: 'Continue',
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.createPin),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.hint, this.icon, this.suffix});

  final String hint;
  final IconData? icon;
  final IconData? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(AppColors.muted),
        ),
        prefixIcon: icon == null ? null : Icon(icon, size: 16),
        suffixIcon: suffix == null ? null : Icon(suffix),
      ),
    );
  }
}
