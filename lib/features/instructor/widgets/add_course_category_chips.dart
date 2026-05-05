import 'package:flutter/material.dart';
import 'package:learnhub/features/instructor/screens/instructor_shared.dart';

import '../../../../core/theme/app_colors.dart';

class AddCourseCategoryChips extends StatelessWidget {
  const AddCourseCategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final titleColor = instructorTitleColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InstructorSectionHeader(
          title: 'Category',
          subtitle:
              'Choose the category students should discover this course in first.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: instructorCategories
              .map((category) {
                final selected = selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  onSelected: (_) => onCategoryChanged(category),
                  backgroundColor: instructorSurfaceColor(context),
                  selectedColor: const Color(
                    AppColors.primary,
                  ).withValues(alpha: 0.14),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? const Color(AppColors.primary)
                        : titleColor,
                  ),
                  side: BorderSide(
                    color: selected
                        ? const Color(AppColors.primary)
                        : instructorBorderColor(context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}
