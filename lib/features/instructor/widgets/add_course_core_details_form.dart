import 'package:flutter/material.dart';
import 'package:learnhub/features/instructor/screens/instructor_shared.dart';

class AddCourseCoreDetailsForm extends StatelessWidget {
  const AddCourseCoreDetailsForm({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.imageUrlController,
    required this.tagsController,
    required this.selectedLevel,
    required this.onLevelChanged,
    required this.levels,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController imageUrlController;
  final TextEditingController tagsController;
  final String selectedLevel;
  final ValueChanged<String> onLevelChanged;
  final List<String> levels;

  @override
  Widget build(BuildContext context) {
    final titleColor = instructorTitleColor(context);
    final secondaryText = instructorMutedColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InstructorSectionHeader(
          title: 'Core Details',
          subtitle:
              'Strong titles, cover media, and a crisp summary make the first impression much stronger.',
        ),
        const SizedBox(height: 12),
        InstructorSurfaceCard(
          child: Column(
            children: [
              TextFormField(
                controller: titleController,
                decoration: instructorInputDecoration(
                  context: context,
                  label: 'Course Title',
                  hint: 'Ex: Flutter State Management Masterclass',
                  icon: Icons.title_rounded,
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) {
                    return 'Course title is required.';
                  }
                  if (text.length < 4) {
                    return 'Title should be at least 4 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: descriptionController,
                minLines: 4,
                maxLines: 6,
                decoration: instructorInputDecoration(
                  context: context,
                  label: 'Description',
                  hint:
                      'Tell students what they will learn and why this course matters.',
                  icon: Icons.description_outlined,
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) {
                    return 'Course description is required.';
                  }
                  if (text.length < 20) {
                    return 'Description should be at least 20 characters.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: levels.contains(selectedLevel)
                    ? selectedLevel
                    : levels.first,
                decoration: instructorInputDecoration(
                  context: context,
                  label: 'Level',
                  hint: 'Choose a level',
                  icon: Icons.stacked_bar_chart_rounded,
                ),
                items: levels
                    .map(
                      (level) => DropdownMenuItem<String>(
                        value: level,
                        child: Text(level, style: TextStyle(color: titleColor)),
                      ),
                    )
                    .toList(growable: false),
                dropdownColor: instructorSurfaceColor(context),
                style: TextStyle(
                  color: titleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                iconEnabledColor: secondaryText,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  onLevelChanged(value);
                },
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ],
    );
  }
}
