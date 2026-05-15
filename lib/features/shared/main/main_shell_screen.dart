import 'dart:async';

import 'package:flutter/material.dart';
import 'package:learnhub/features/course/providers/course_provider.dart';
import 'package:learnhub/features/home/screens/home_screen.dart';
import 'package:learnhub/features/student_side/learning/screens/my_learning_screen.dart';
import 'package:learnhub/features/student_side/profile/screens/profile_screen.dart';
import 'package:learnhub/features/student_side/wishlist/wishlist_screen.dart';
import 'package:learnhub/features/shared/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

import '../../../data/services/firestore_service.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'widgets/main_shell_bottom_nav_bar.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courseProvider = context.read<CourseProvider>();
      final userId = context.read<AuthProvider>().currentUser?.id;
      unawaited(
        FirestoreService.instance.ensureAdminCoursesSeeded().catchError((_) {}),
      );
      courseProvider.loadInitialData(userId: userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final isArabic = appState.isArabic;
    final items = <MainShellNavItemData>[
      MainShellNavItemData(
        label: isArabic ? 'الرئيسية' : 'Home',
        icon: Icons.home_rounded,
        outlinedIcon: Icons.home_outlined,
      ),
      MainShellNavItemData(
        label: isArabic ? 'كورساتي' : 'My Courses',
        icon: Icons.menu_book_rounded,
        outlinedIcon: Icons.menu_book_outlined,
      ),
      MainShellNavItemData(
        label: isArabic ? 'المحفوظات' : 'Bookmark',
        icon: Icons.bookmark_rounded,
        outlinedIcon: Icons.bookmark_outline_rounded,
      ),
      MainShellNavItemData(
        label: isArabic ? 'الملف الشخصي' : 'Profile',
        icon: Icons.person_rounded,
        outlinedIcon: Icons.person_outline_rounded,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          MyLearningScreen(embedded: true),
          WishlistScreen(embedded: true),
          ProfileScreen(embedded: true),
        ],
      ),
      bottomNavigationBar: MainShellBottomNavBar(
        items: items,
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
      ),
    );
  }
}
