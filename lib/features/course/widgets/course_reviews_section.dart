import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/edu_media.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/route_args.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/course.dart';
import '../../../../domain/entities/course_review.dart';

class CourseReviewsSection extends StatelessWidget {
  const CourseReviewsSection({
    super.key,
    required this.reviews,
    required this.course,
    required this.surfaceColor,
    required this.outlineColor,
    required this.isDark,
  });

  final List<CourseReview> reviews;
  final Course course;
  final Color surfaceColor;
  final Color outlineColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final secondaryText = colorScheme.onSurface.withValues(alpha: 0.72);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Reviews',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.courseReviews,
                    arguments: CourseModuleArgs(course: course),
                  );
                },
                child: const Text(
                  'SEE ALL',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          ...reviews
              .take(2)
              .map(
                (review) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: isDark ? Border.all(color: outlineColor) : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const EduAvatar(
                          imageUrl:
                              'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=200&q=80',
                          size: 34,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    review.userName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F6FF),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(AppColors.primary),
                                      ),
                                    ),
                                    child: Text(
                                      '⭐ ${review.rating.toStringAsFixed(1)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                review.comment,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
