import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class EduOutlineButton extends StatelessWidget {
  const EduOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 46,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFE7EEF8),
          side: const BorderSide(color: Color(0xFFD6E0EE)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(AppColors.dark),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
