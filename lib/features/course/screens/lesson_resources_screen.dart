import 'package:flutter/material.dart';
import 'package:learnhub/features/course/providers/course_provider.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/lesson.dart';

class LessonResourcesScreen extends StatelessWidget {
  const LessonResourcesScreen({
    super.key,
    required this.lesson,
    required this.courseTitle,
  });

  final Lesson lesson;
  final String courseTitle;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final isDownloaded = provider.isLessonDownloaded(lesson.id);

    final resources = <String>[
      '${lesson.title} - Slides.pdf',
      '${lesson.title} - Source Code.zip',
      '${lesson.title} - Assignment.md',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Lesson Resources')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            courseTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(lesson.title),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => provider.toggleLessonDownload(lesson.id),
            icon: Icon(
              isDownloaded
                  ? Icons.download_done_rounded
                  : Icons.download_rounded,
            ),
            label: Text(isDownloaded ? 'Downloaded' : 'Download for offline'),
          ),
          const SizedBox(height: 14),
          ...resources.map(
            (resource) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  title: Text(resource),
                  leading: const Icon(Icons.description_outlined),
                  trailing: const Icon(Icons.open_in_new_rounded),
                  onTap: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Open: $resource')));
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
