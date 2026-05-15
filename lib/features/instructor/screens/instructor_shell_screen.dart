import 'package:flutter/material.dart';
import 'package:learnhub/features/shared/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

import 'package:learnhub/core/theme/app_colors.dart';
import 'instructor_add_course_screen.dart';
import 'instructor_dashboard_screen.dart';
import 'instructor_my_courses_screen.dart';
import 'instructor_profile_screen.dart';

class InstructorShellScreen extends StatefulWidget {
  const InstructorShellScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<InstructorShellScreen> createState() => _InstructorShellScreenState();
}

class _InstructorShellScreenState extends State<InstructorShellScreen> {
  late int _index = widget.initialIndex.clamp(0, 3);

  void _selectTab(int index) {
    if (_index == index) {
      return;
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final pages = <Widget>[
      InstructorDashboardScreen(
        embedded: true,
        onOpenCourses: () => _selectTab(1),
        onOpenCreate: () => _selectTab(2),
        onOpenProfile: () => _selectTab(3),
      ),
      InstructorMyCoursesScreen(
        embedded: true,
        onCreateCourse: () => _selectTab(2),
      ),
      InstructorAddCourseScreen(embedded: true, onSaved: () => _selectTab(1)),
      const InstructorProfileScreen(embedded: true),
    ];

    final items = <_InstructorNavItemData>[
      _InstructorNavItemData(
        label: appState.isArabic ? 'نظرة عامة' : 'Overview',
        icon: Icons.dashboard_customize_rounded,
        outlinedIcon: Icons.dashboard_customize_outlined,
      ),
      _InstructorNavItemData(
        label: appState.isArabic ? 'الكورسات' : 'Courses',
        icon: Icons.library_books_rounded,
        outlinedIcon: Icons.library_books_outlined,
      ),
      _InstructorNavItemData(
        label: appState.isArabic ? 'إضافة' : 'Create',
        icon: Icons.add_circle_rounded,
        outlinedIcon: Icons.add_circle_outline_rounded,
      ),
      _InstructorNavItemData(
        label: appState.isArabic ? 'الملف الشخصي' : 'Profile',
        icon: Icons.person_rounded,
        outlinedIcon: Icons.person_outline_rounded,
      ),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark
          ? const Color(0xFF09111F)
          : const Color(AppColors.bg),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF09111F), Color(0xFF0F1729)]
                : const [Color(0xFFF5FBFF), Color(0xFFEEF4FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xFF101A2D), Color(0xFF0D1525)]
                  : const [Color(0xFFFFFFFF), Color(0xFFF7FBFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF24324B)
                  : const Color(AppColors.line),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.11),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: List<Widget>.generate(items.length, (itemIndex) {
              final item = items[itemIndex];
              final selected = _index == itemIndex;
              return Expanded(
                child: _InstructorShellNavItem(
                  item: item,
                  selected: selected,
                  baseColor: onSurface,
                  onTap: () => _selectTab(itemIndex),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _InstructorShellNavItem extends StatelessWidget {
  const _InstructorShellNavItem({
    required this.item,
    required this.selected,
    required this.baseColor,
    required this.onTap,
  });

  final _InstructorNavItemData item;
  final bool selected;
  final Color baseColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF1CCCBF), Color(0xFF13B6C5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(22),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(
                        AppColors.primary,
                      ).withValues(alpha: 0.24),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? item.icon : item.outlinedIcon,
                size: 20,
                color: selected
                    ? Colors.white
                    : baseColor.withValues(alpha: 0.72),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: selected
                      ? Colors.white
                      : baseColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructorNavItemData {
  const _InstructorNavItemData({
    required this.label,
    required this.icon,
    required this.outlinedIcon,
  });

  final String label;
  final IconData icon;
  final IconData outlinedIcon;
}
