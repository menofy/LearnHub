import 'package:flutter/material.dart';

class ProfileMenuSection extends StatelessWidget {
  const ProfileMenuSection({
    super.key,
    required this.isArabic,
    required this.languageValue,
    required this.themeValue,
    required this.onEditProfileTap,
    required this.onNotificationsTap,
    required this.onSecurityTap,
    required this.onLanguageTap,
    required this.onThemeTap,
    required this.onTermsTap,
  });

  final bool isArabic;
  final String languageValue;
  final String themeValue;
  final VoidCallback onEditProfileTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onSecurityTap;
  final VoidCallback onLanguageTap;
  final VoidCallback onThemeTap;
  final VoidCallback onTermsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _ProfileMenuRow(
            icon: Icons.person_outline_rounded,
            label: isArabic ? 'تعديل الملف الشخصي' : 'Edit Profile',
            onTap: onEditProfileTap,
          ),
          Divider(height: 1, indent: 56, color: theme.dividerColor),
          _ProfileMenuRow(
            icon: Icons.notifications_none_rounded,
            label: isArabic ? 'الإشعارات' : 'Notifications',
            onTap: onNotificationsTap,
          ),
          Divider(height: 1, indent: 56, color: theme.dividerColor),
          _ProfileMenuRow(
            icon: Icons.shield_outlined,
            label: isArabic ? 'الأمان' : 'Security',
            onTap: onSecurityTap,
          ),
          Divider(height: 1, indent: 56, color: theme.dividerColor),
          _ProfileMenuRow(
            icon: Icons.language_rounded,
            label: isArabic ? 'اللغة' : 'Language',
            value: languageValue,
            onTap: onLanguageTap,
          ),
          Divider(height: 1, indent: 56, color: theme.dividerColor),
          _ProfileMenuRow(
            icon: Icons.dark_mode_outlined,
            label: isArabic ? 'الوضع الداكن' : 'Dark Mode',
            value: themeValue,
            onTap: onThemeTap,
          ),
          Divider(height: 1, indent: 56, color: theme.dividerColor),
          _ProfileMenuRow(
            icon: Icons.verified_user_outlined,
            label: isArabic ? 'الشروط والأحكام' : 'Terms & Conditions',
            onTap: onTermsTap,
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 24, color: colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (value != null)
                Text(
                  value!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
