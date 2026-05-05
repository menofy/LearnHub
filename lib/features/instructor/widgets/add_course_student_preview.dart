import 'package:flutter/material.dart';
import 'package:learnhub/features/instructor/screens/instructor_shared.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/course.dart';

class AddCourseStudentPreview extends StatelessWidget {
  const AddCourseStudentPreview({
    super.key,
    required this.title,
    required this.description,
    required this.selectedCategory,
    required this.selectedLevel,
    required this.isPublished,
    required this.isFree,
    required this.price,
    required this.mediaSourceType,
    required this.playlistId,
    required this.uploadedVideoCount,
    required this.tags,
  });

  final String title;
  final String description;
  final String selectedCategory;
  final String selectedLevel;
  final bool isPublished;
  final bool isFree;
  final String price;
  final String mediaSourceType;
  final String playlistId;
  final int uploadedVideoCount;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final titleColor = instructorTitleColor(context);
    final secondaryText = instructorMutedColor(context);
    final isDark = instructorIsDark(context);
    final mediaSummary = mediaSourceType == Course.uploadMediaSource
        ? uploadedVideoCount <= 0
              ? 'Upload-ready video manager'
              : uploadedVideoCount == 1
              ? '1 managed uploaded video'
              : '$uploadedVideoCount managed uploaded videos'
        : playlistId.isNotEmpty
        ? 'Structured from playlist'
        : 'Single-source lesson flow';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InstructorSectionHeader(
          title: 'Student Preview',
          subtitle: 'See how the course pitch feels before it goes live.',
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: instructorSurfaceColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: instructorBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 140,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE8F4F8), Color(0xFFF0F9FB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.play_circle_outline_rounded,
                        size: 56,
                        color: Color(AppColors.primary),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: InstructorPill(
                        label: isPublished ? 'Published' : 'Draft',
                        icon: isPublished
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        backgroundColor: Colors.white.withValues(alpha: 0.92),
                        foregroundColor: const Color(0xFF16213B),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        InstructorPill(
                          label: selectedCategory,
                          icon: Icons.sell_outlined,
                        ),
                        InstructorPill(
                          label: selectedLevel,
                          icon: Icons.school_outlined,
                          backgroundColor: const Color(0xFFF3ECFF),
                          foregroundColor: const Color(0xFF6C47D9),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title.isEmpty ? 'Add a course title' : title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: titleColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description.isEmpty
                          ? 'Add a stronger summary so students instantly understand the promise of this course.'
                          : description,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: secondaryText,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    if (tags.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tags
                            .take(4)
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    AppColors.primary,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(AppColors.primary),
                                  ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    if (tags.isNotEmpty) const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.menu_book_outlined,
                          size: 14,
                          color: Color(AppColors.primary),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          mediaSummary,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: secondaryText,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          isFree
                              ? 'Free'
                              : '\$${(double.tryParse(price) ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
