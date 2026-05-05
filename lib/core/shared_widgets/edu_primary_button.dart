import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class EduPrimaryButton extends StatelessWidget {
  const EduPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 46,
    this.expanded = true,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final bool expanded;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;
    final button = SizedBox(
      height: height,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        elevation: isDisabled ? 0 : 5,
        shadowColor: const Color(AppColors.primary).withValues(alpha: 0.36),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: isDisabled ? null : onPressed,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: isDisabled
                    ? [
                        const Color(AppColors.primary).withValues(alpha: 0.45),
                        const Color(AppColors.primary).withValues(alpha: 0.38),
                      ]
                    : const [Color(0xFF14CCC2), Color(0xFF11B9C1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  Expanded(
                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? Colors.white.withValues(alpha: 0.72)
                          : const Color(0xFFE9FFFC),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: isDisabled
                          ? const Color(AppColors.muted)
                          : const Color(AppColors.primary),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (expanded) {
      return button;
    }

    return IntrinsicWidth(child: button);
  }
}
