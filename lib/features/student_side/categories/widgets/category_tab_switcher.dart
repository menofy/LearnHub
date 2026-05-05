import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class CategoryTabSwitcher extends StatelessWidget {
  const CategoryTabSwitcher({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1A8C7F) : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : const Color(AppColors.dark),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
