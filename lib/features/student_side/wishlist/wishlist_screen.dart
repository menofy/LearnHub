import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/category_chip.dart';
import 'package:learnhub/core/shared_widgets/content_loading_skeleton.dart';
import 'package:learnhub/core/shared_widgets/empty_state.dart';
import 'package:learnhub/core/shared_widgets/error_retry_state.dart';
import 'package:learnhub/features/course/providers/course_provider.dart';
import 'package:learnhub/features/course/widgets/course_card.dart';
import 'package:provider/provider.dart';

import 'package:learnhub/core/navigation/app_routes.dart';
import '../../../core/navigation/route_args.dart';
import 'package:learnhub/core/theme/app_colors.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  String _selected = 'All';

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
    final hasNoCourses = provider.courses.isEmpty;
    final colorScheme = Theme.of(context).colorScheme;

    if (provider.isLoading && hasNoCourses) {
      const loading = SafeArea(
        bottom: false,
        child: ContentLoadingSkeleton(itemCount: 5, tileHeight: 100),
      );
      if (widget.embedded) {
        return loading;
      }
      return const Scaffold(body: loading);
    }

    if (provider.errorMessage != null && hasNoCourses) {
      final error = SafeArea(
        bottom: false,
        child: ErrorRetryState(
          message: provider.errorMessage!,
          onRetry: () =>
              context.read<CourseProvider>().loadCourses(force: true),
        ),
      );
      if (widget.embedded) {
        return error;
      }
      return Scaffold(body: error);
    }

    final wishlist = provider.wishlistCourses;
    final categories = <String>{'All', ...provider.categories}.toList();

    final visible = _selected == 'All'
        ? wishlist
        : wishlist.where((course) => course.category == _selected).toList();

    final content = SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          children: [
            Row(
              children: [
                if (!widget.embedded)
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                Text(
                  'My Bookmark',
                  style: TextStyle(
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return CategoryChip(
                    label: category,
                    isSelected: _selected == category,
                    onTap: () => setState(() => _selected = category),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: visible.isEmpty
                  ? const EmptyState(
                      icon: Icons.bookmark_border_rounded,
                      title: 'Wishlist is empty',
                      subtitle:
                          'Tap bookmark icon on any course to add it here.',
                    )
                  : ListView.separated(
                      itemCount: visible.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final course = visible[index];
                        return Dismissible(
                          key: ValueKey(course.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            decoration: BoxDecoration(
                              color: const Color(AppColors.danger),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 18),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) =>
                              provider.toggleWishlist(course.id),
                          child: CourseCard(
                            course: course,
                            isBookmarked: true,
                            onBookmarkTap: () =>
                                provider.toggleWishlist(course.id),
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.courseDetails,
                                arguments: CourseDetailsArgs(course: course),
                              );
                            },
                            isHorizontal: false,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(body: content);
  }
}
