import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/content_loading_skeleton.dart';
import 'package:learnhub/core/shared_widgets/error_retry_state.dart';
import 'package:learnhub/features/course/providers/course_provider.dart';
import 'package:provider/provider.dart';

import 'package:learnhub/core/navigation/app_routes.dart';
import '../../../core/navigation/route_args.dart';
import 'package:learnhub/core/theme/app_colors.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CourseProvider>();
      if (provider.courses.isEmpty) {
        provider.loadCourses();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final categories = provider.categories;

    if (provider.isLoading && categories.isEmpty) {
      return const Scaffold(
        body: SafeArea(
          child: ContentLoadingSkeleton(itemCount: 8, tileHeight: 88),
        ),
      );
    }

    if (provider.errorMessage != null && categories.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: ErrorRetryState(
            message: provider.errorMessage!,
            onRetry: () =>
                context.read<CourseProvider>().loadCourses(force: true),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Text(
                    'All Category',
                    style: TextStyle(
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                      color: Color(AppColors.dark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: Color(AppColors.dark),
                      size: 21,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Search for..',
                        style: TextStyle(
                          color: Color(AppColors.muted),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(AppColors.primary),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  itemCount: categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 124,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.categoryCourses,
                          arguments: CategoryCoursesArgs(category: category),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _categoryColor(
                                index,
                              ).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _categoryIcon(category),
                              color: _categoryColor(index),
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(AppColors.dark),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    final value = category.toLowerCase();
    if (value.contains('design')) return Icons.auto_awesome;
    if (value.contains('program')) return Icons.code_rounded;
    if (value.contains('backend')) return Icons.storage_rounded;
    if (value.contains('computer')) return Icons.computer_rounded;
    if (value.contains('product')) return Icons.lightbulb_outline_rounded;
    if (value.contains('testing')) return Icons.fact_check_outlined;
    return Icons.widgets_outlined;
  }

  Color _categoryColor(int index) {
    const colors = [
      Color(0xFF9C74D5),
      Color(0xFF4EA8FF),
      Color(0xFF1A8C7F),
      Color(0xFF2B59C3),
      Color(0xFF17C7BE),
      Color(0xFFFF8A00),
    ];
    return colors[index % colors.length];
  }
}
