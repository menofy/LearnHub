import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Ratings Section
class InstructorRatingsSection extends StatelessWidget {
  const InstructorRatingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Sample instructor reviews data
    final reviews = [
      {
        'name': 'Ahmed Hassan',
        'rating': 5,
        'comment':
            'Excellent instructor! Very knowledgeable and patient with students.',
        'avatar': 'https://i.pravatar.cc/150?img=1',
      },
      {
        'name': 'Fatima Ali',
        'rating': 5,
        'comment': 'Great course content and clear explanations. Highly recommended!',
        'avatar': 'https://i.pravatar.cc/150?img=2',
      },
      {
        'name': 'Mohamed Amin',
        'rating': 4,
        'comment': 'Good instructor but could improve on pacing. Overall satisfied.',
        'avatar': 'https://i.pravatar.cc/150?img=3',
      },
    ];

    return Column(
      children: reviews
          .map((review) => _ReviewCard(
                name: review['name'] as String,
                rating: review['rating'] as int,
                comment: review['comment'] as String,
                avatar: review['avatar'] as String,
                isDark: isDark,
                colorScheme: colorScheme,
              ))
          .toList(),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.name,
    required this.rating,
    required this.comment,
    required this.avatar,
    required this.isDark,
    required this.colorScheme,
  });

  final String name;
  final int rating;
  final String comment;
  final String avatar;
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? colorScheme.outline.withValues(alpha: 0.55)
              : const Color(AppColors.line),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(avatar),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 14,
                            color: const Color(0xFFFFC83D),
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          '$rating.0',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.78),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
