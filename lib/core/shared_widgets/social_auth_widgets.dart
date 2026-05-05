import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/theme/app_colors.dart';

enum SocialBrand { google, apple }

class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    super.key,
    required this.label,
    required this.brand,
    required this.onTap,
  });

  final String label;
  final SocialBrand brand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? colorScheme.outline.withValues(alpha: 0.7)
                : const Color(AppColors.line),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _BrandIcon(brand: brand, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SocialCircleButton extends StatelessWidget {
  const SocialCircleButton({super.key, required this.brand, this.onTap});

  final SocialBrand brand;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark
                ? colorScheme.outline.withValues(alpha: 0.7)
                : const Color(AppColors.line),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.03),
              blurRadius: 7,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: _BrandIcon(brand: brand, size: 14)),
      ),
    );
  }
}

class _BrandIcon extends StatelessWidget {
  const _BrandIcon({required this.brand, required this.size});

  final SocialBrand brand;
  final double size;

  @override
  Widget build(BuildContext context) {
    switch (brand) {
      case SocialBrand.google:
        return FaIcon(
          FontAwesomeIcons.google,
          size: size,
          color: const Color(0xFFDB4437),
        );
      case SocialBrand.apple:
        return FaIcon(
          FontAwesomeIcons.apple,
          size: size + 1,
          color: const Color(0xFF1F1F1F),
        );
    }
  }
}
