import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/edu_media.dart';
import 'package:learnhub/core/theme/app_colors.dart';
import 'package:learnhub/domain/entities/course.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.compact = false,
    this.isHorizontal = true,
    this.isBookmarked = false,
    this.onBookmarkTap,
  });

  final Course course;
  final VoidCallback onTap;
  final bool compact;
  final bool isHorizontal;
  final bool isBookmarked;
  final VoidCallback? onBookmarkTap;

  String get _courseBadge => course.isAdminCourse ? 'Featured' : 'Latest';

  String get _courseSourceLabel {
    if (course.usesUploadedVideos) {
      return 'Upload course';
    }
    if (course.playlistId.trim().isNotEmpty) {
      return 'Playlist course';
    }
    if (course.primaryPlayableVideoUrl.trim().isNotEmpty) {
      return 'Video course';
    }
    return 'Course';
  }

  String get _courseMetaLabel {
    final pricing = course.isFree
        ? 'Free'
        : '\$${course.price.toStringAsFixed(course.price.truncateToDouble() == course.price ? 0 : 2)}';
    return '${course.level} • $pricing • $_courseSourceLabel';
  }

  String get _instructorLabel {
    final value = course.instructorName.trim();
    return value.isEmpty ? 'LearnHub' : value;
  }

  @override
  Widget build(BuildContext context) {
    final child = isHorizontal
        ? _buildVerticalCard(context)
        : _buildHorizontalCard(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: child,
      ),
    );
  }

  Widget _buildVerticalCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF101A2D) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF24324B)
        : const Color(AppColors.line).withValues(alpha: 0.6);
    final titleColor = isDark ? Colors.white : const Color(AppColors.dark);
    final secondaryTextColor = isDark
        ? Colors.white.withValues(alpha: 0.78)
        : const Color(AppColors.dark).withValues(alpha: 0.7);
    final tertiaryTextColor = isDark
        ? Colors.white.withValues(alpha: 0.62)
        : const Color(AppColors.dark).withValues(alpha: 0.55);
    final badgeBgColor = isDark
        ? const Color(0xFF3A2410)
        : const Color(0xFFFFF5E6);

    return Container(
      width: 180,
      height: 240,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              EduCourseThumb(
                imageUrl: course.preferredPreviewImageUrl,
                videoUrl: course.primaryPlayableVideoUrl,
                playlistId: course.usesUploadedVideos ? '' : course.playlistId,
                width: double.infinity,
                height: 120,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.25),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: isDark
                      ? const Color(0xFF162238).withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: onBookmarkTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 16,
                        color: const Color(AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          course.category,
                          style: const TextStyle(
                            color: Color(0xFFFF8A00),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        course.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _courseBadge,
                        style: TextStyle(
                          color: Color(AppColors.primary),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 12,
                            color: Color(AppColors.primary),
                          ),
                          const SizedBox(width: 3),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _instructorLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: secondaryTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _courseMetaLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: tertiaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF101A2D) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF24324B)
        : const Color(AppColors.line).withValues(alpha: 0.92);
    final titleColor = isDark ? Colors.white : const Color(AppColors.dark);
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.78)
        : const Color(AppColors.muted);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EduCourseThumb(
            imageUrl: course.preferredPreviewImageUrl,
            videoUrl: course.primaryPlayableVideoUrl,
            playlistId: course.usesUploadedVideos ? '' : course.playlistId,
            width: 95,
            height: 100,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              bottomLeft: Radius.circular(18),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.category,
                    style: const TextStyle(
                      color: Color(0xFFFF8A00),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _courseBadge,
                    style: const TextStyle(
                      color: Color(AppColors.primary),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 12,
                        color: Color(AppColors.primary),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          _instructorLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _courseMetaLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ).copyWith(color: subtitleColor),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10, right: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onBookmarkTap,
                borderRadius: BorderRadius.circular(16),
                child: Icon(
                  isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: 16,
                  color: const Color(AppColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
