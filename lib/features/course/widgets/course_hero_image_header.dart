import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/edu_media.dart';

import '../../../../core/theme/app_colors.dart';

class CourseHeroImageHeader extends StatelessWidget {
  const CourseHeroImageHeader({
    super.key,
    required this.imageUrl,
    required this.videoUrl,
    required this.playlistId,
    required this.onBack,
    required this.onPlayFirst,
    required this.hasLessons,
  });

  final String imageUrl;
  final String videoUrl;
  final String playlistId;
  final VoidCallback onBack;
  final VoidCallback onPlayFirst;
  final bool hasLessons;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Stack(
        children: [
          Positioned.fill(
            child: EduCourseThumb(
              imageUrl: imageUrl,
              videoUrl: videoUrl,
              playlistId: playlistId,
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.zero,
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.28),
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.36),
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 10,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Color(AppColors.bg),
              ),
            ),
          ),
          if (hasLessons)
            Positioned(
              right: 14,
              bottom: 14,
              child: GestureDetector(
                onTap: onPlayFirst,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(AppColors.primary),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
