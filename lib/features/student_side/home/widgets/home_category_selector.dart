import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/category_chip.dart';

class HomeCategorySelector extends StatelessWidget {
  const HomeCategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories
            .map(
              (category) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CategoryChip(
                  label: category,
                  isSelected: selectedCategory == category,
                  onTap: () => onSelected(category),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
