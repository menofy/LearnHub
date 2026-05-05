import 'package:flutter/material.dart';
import 'package:learnhub/features/course/providers/course_provider.dart';

class SearchFilterChips extends StatelessWidget {
  const SearchFilterChips({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          return ChoiceChip(
            label: Text(option),
            selected: selectedValue == option,
            onSelected: (_) => onSelected(option),
          );
        },
      ),
    );
  }
}

class SearchSortChips extends StatelessWidget {
  const SearchSortChips({
    super.key,
    required this.selectedSort,
    required this.onSelected,
  });

  final CourseSortOption selectedSort;
  final ValueChanged<CourseSortOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: CourseSortOption.values
            .map((sortOption) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_sortLabel(sortOption)),
                  selected: selectedSort == sortOption,
                  onSelected: (_) => onSelected(sortOption),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  String _sortLabel(CourseSortOption option) {
    switch (option) {
      case CourseSortOption.recommended:
        return 'Recommended';
      case CourseSortOption.newest:
        return 'Newest';
      case CourseSortOption.rating:
        return 'Rating';
      case CourseSortOption.learners:
        return 'Learners';
      case CourseSortOption.priceLowToHigh:
        return 'Price';
    }
  }
}
