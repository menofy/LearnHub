import 'package:flutter/material.dart';
import 'package:learnhub/domain/entities/course.dart';

class ProgressCourseTile extends StatelessWidget {
  const ProgressCourseTile({
    super.key,
    required this.course,
    required this.progress,
    required this.onTap,
  });

  final Course course;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progressValue = progress.clamp(0, 1).toDouble();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                course.instructor,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: progressValue),
              const SizedBox(height: 6),
              Text(
                '${(progressValue * 100).toStringAsFixed(0)}% completed',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
