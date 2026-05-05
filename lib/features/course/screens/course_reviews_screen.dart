import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';
import 'package:learnhub/features/course/providers/course_provider.dart';
import 'package:provider/provider.dart';

import 'package:learnhub/core/navigation/app_routes.dart';
import '../../../core/navigation/route_args.dart';
import 'package:learnhub/core/theme/app_colors.dart';
import '../../../domain/entities/course.dart';

class CourseReviewsScreen extends StatefulWidget {
  const CourseReviewsScreen({super.key, required this.course});

  final Course course;

  @override
  State<CourseReviewsScreen> createState() => _CourseReviewsScreenState();
}

class _CourseReviewsScreenState extends State<CourseReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadCourseReviews(widget.course.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final reviews = provider.reviewsByCourse(widget.course.id);

    final average = reviews.isEmpty
        ? 4.8
        : reviews.map((e) => e.rating).reduce((a, b) => a + b) / reviews.length;

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
                    'Reviews',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(AppColors.dark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                average.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Color(AppColors.dark),
                ),
              ),
              const SizedBox(height: 2),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_rounded, color: Color(0xFFFFC83D), size: 17),
                  Icon(Icons.star_rounded, color: Color(0xFFFFC83D), size: 17),
                  Icon(Icons.star_rounded, color: Color(0xFFFFC83D), size: 17),
                  Icon(Icons.star_rounded, color: Color(0xFFFFC83D), size: 17),
                  Icon(
                    Icons.star_half_rounded,
                    color: Color(0xFFFFC83D),
                    size: 17,
                  ),
                ],
              ),
              Text(
                'Based on ${reviews.length} Reviews',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(AppColors.muted),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: reviews.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
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
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Color(AppColors.dark),
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
                                const SizedBox(height: 2),
                                Text(
                                  review.comment,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(AppColors.muted),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.favorite_rounded,
                                      size: 14,
                                      color: Color(0xFFEE4C5A),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '760',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      '2 Weeks Agos',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(AppColors.muted),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              EduPrimaryButton(
                label: 'Write a Review',
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.writeReview,
                    arguments: CourseModuleArgs(course: widget.course),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
