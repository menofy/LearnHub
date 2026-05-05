import 'package:flutter/material.dart';
import 'package:learnhub/features/instructor/screens/instructor_shared.dart';

class AddCourseOutcomesRequirementsForm extends StatelessWidget {
  const AddCourseOutcomesRequirementsForm({
    super.key,
    required this.outcomesController,
    required this.requirementsController,
  });

  final TextEditingController outcomesController;
  final TextEditingController requirementsController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InstructorSectionHeader(
          title: 'Learning Outcomes & Requirements',
          subtitle:
              'Structure the promise of the course so students understand who it is for.',
        ),
        const SizedBox(height: 12),
        InstructorSurfaceCard(
          child: Column(
            children: [
              TextFormField(
                controller: outcomesController,
                minLines: 3,
                maxLines: 5,
                decoration: instructorInputDecoration(
                  context: context,
                  label: 'What students will achieve',
                  hint:
                      'Build scalable Flutter UI\nUnderstand state management trade-offs',
                  icon: Icons.flag_outlined,
                  helperText:
                      'Use a new line or comma for each learning outcome.',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: requirementsController,
                minLines: 3,
                maxLines: 5,
                decoration: instructorInputDecoration(
                  context: context,
                  label: 'Requirements',
                  hint: 'Basic Dart syntax\nFlutter SDK installed',
                  icon: Icons.checklist_rounded,
                  helperText: 'Use a new line or comma for each requirement.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
