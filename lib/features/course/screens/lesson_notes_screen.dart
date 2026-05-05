import 'package:flutter/material.dart';
import 'package:learnhub/features/course/providers/course_provider.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/lesson.dart';

class LessonNotesScreen extends StatefulWidget {
  const LessonNotesScreen({
    super.key,
    required this.lesson,
    required this.courseTitle,
  });

  final Lesson lesson;
  final String courseTitle;

  @override
  State<LessonNotesScreen> createState() => _LessonNotesScreenState();
}

class _LessonNotesScreenState extends State<LessonNotesScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initial = context.read<CourseProvider>().noteForLesson(
      widget.lesson.id,
    );
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    context.read<CourseProvider>().saveLessonNote(
      lessonId: widget.lesson.id,
      note: _controller.text,
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Notes saved successfully.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lesson Notes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.courseTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(widget.lesson.title),
            const SizedBox(height: 14),
            Expanded(
              child: TextField(
                controller: _controller,
                expands: true,
                maxLines: null,
                minLines: null,
                decoration: const InputDecoration(
                  hintText: 'Write your notes here...',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Notes'),
            ),
          ],
        ),
      ),
    );
  }
}
