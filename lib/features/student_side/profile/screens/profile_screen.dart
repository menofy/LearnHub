import 'package:flutter/material.dart';
import 'package:learnhub/core/navigation/app_routes.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:learnhub/features/student_side/profile/widgets/profile_header_card.dart';
import 'package:learnhub/features/student_side/profile/widgets/profile_menu_section.dart';
import 'package:learnhub/features/shared/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final appState = context.watch<AppStateProvider>();
    final user = auth.currentUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isArabic = appState.isArabic;

    if (user == null) {
      return Center(
        child: Text(isArabic ? 'سجل الدخول أولاً.' : 'Please login first.'),
      );
    }

    final content = SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        children: [
          Text(
            isArabic ? 'ملفي الشخصي' : 'My Profile',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isArabic
                ? 'إدارة إعدادات الحساب والتفضيلات.'
                : 'Manage your account settings and preferences',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 18),
          ProfileHeaderCard(user: user, isArabic: isArabic),
          const SizedBox(height: 18),
          ProfileMenuSection(
            isArabic: isArabic,
            languageValue: appState.isArabic
                ? (isArabic ? 'العربية' : 'Arabic')
                : 'English',
            themeValue: appState.themeMode == ThemeMode.dark
                ? (isArabic ? 'مفعل' : 'On')
                : (isArabic ? 'إيقاف' : 'Off'),
            onEditProfileTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.editProfile),
            onNotificationsTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.notificationSettings),
            onSecurityTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.changePassword),
            onLanguageTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.languageSettings),
            onThemeTap: () {
              final next = appState.themeMode == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
              appState.setThemeMode(next);
            },
            onTermsTap: () => Navigator.of(context).pushNamed(AppRoutes.terms),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: auth.isLoading
                  ? null
                  : () => context.read<AuthProvider>().logout(),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: Text(isArabic ? 'تسجيل الخروج' : 'Logout'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: colorScheme.primary, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (embedded) {
      return content;
    }

    return Scaffold(body: content);
  }
}
