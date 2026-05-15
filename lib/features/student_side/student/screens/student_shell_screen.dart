import 'package:flutter/material.dart';
import 'package:learnhub/core/theme/app_colors.dart';
import 'package:learnhub/features/student_side/profile/screens/profile_screen.dart';
import 'package:learnhub/features/shared/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

import 'student_home_screen.dart';

class StudentShellScreen extends StatefulWidget {
  const StudentShellScreen({super.key});

  @override
  State<StudentShellScreen> createState() => _StudentShellScreenState();
}

class _StudentShellScreenState extends State<StudentShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final pages = const [StudentHomeScreen(), ProfileScreen(embedded: true)];
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF101A2D) : Colors.white,
        indicatorColor: const Color(AppColors.primary).withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            color: selected
                ? const Color(AppColors.primary)
                : onSurface.withValues(alpha: 0.65),
          );
        }),
      ),
      child: Scaffold(
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: NavigationBar(
          height: 72,
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: appState.isArabic ? 'الرئيسية' : 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(Icons.person_rounded),
              label: appState.isArabic ? 'الملف الشخصي' : 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
