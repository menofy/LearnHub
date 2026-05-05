import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class CategoryFilterBottomSheet extends StatefulWidget {
  const CategoryFilterBottomSheet({
    super.key,
    required this.currentSortBy,
    required this.onSortChanged,
    required this.onClear,
    required this.onApply,
  });

  final String currentSortBy;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onClear;
  final VoidCallback onApply;

  @override
  State<CategoryFilterBottomSheet> createState() =>
      _CategoryFilterBottomSheetState();
}

class _CategoryFilterBottomSheetState extends State<CategoryFilterBottomSheet> {
  late String _sortBy;

  @override
  void initState() {
    super.initState();
    _sortBy = widget.currentSortBy;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: const BoxDecoration(
        color: Color(AppColors.bg),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Filter',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(AppColors.dark),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  widget.onClear();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(AppColors.muted),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView(
              children: const [
                _FilterSection(
                  title: 'SubCategories:',
                  items: [
                    '3D Design',
                    'Web Development',
                    '3D Animation',
                    'Graphic Design',
                    'SEO & Marketing',
                    'Arts & Humanities',
                  ],
                ),
                _FilterSection(
                  title: 'Levels:',
                  items: [
                    'All Levels',
                    'Beginners',
                    'Intermediate',
                    'Expert',
                  ],
                ),
                _FilterSection(
                  title: 'Features:',
                  items: [
                    'All Caption',
                    'Quizzes',
                    'Coding Exercise',
                    'Practice Tests',
                  ],
                ),
                _FilterSection(
                  title: 'Rating:',
                  items: [
                    '4.5 & Up Above',
                    '4.0 & Up Above',
                    '3.5 & Up Above',
                    '3.0 & Up Above',
                  ],
                ),
                _FilterSection(
                  title: 'Video Durations:',
                  items: [
                    '0-2 Hours',
                    '3-6 Hours',
                    '7-16 Hours',
                    '17+ Hours',
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text(
                  'Sort by',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(AppColors.dark),
                  ),
                ),
                const Spacer(),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    items: const [
                      DropdownMenuItem(
                        value: 'relevance',
                        child: Text('Relevance'),
                      ),
                      DropdownMenuItem(
                        value: 'title',
                        child: Text('Title A-Z'),
                      ),
                      DropdownMenuItem(
                        value: 'popular',
                        child: Text('Popular First'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _sortBy = value);
                      widget.onSortChanged(value);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _FilterApplyButton(
              onTap: () {
                widget.onApply();
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(AppColors.dark),
            ),
          ),
          const SizedBox(height: 8),
          ...items.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: entry.key % 3 == 1
                          ? const Color(AppColors.primary)
                          : const Color(AppColors.bg),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFFAFC0D7)),
                    ),
                    child: entry.key % 3 == 1
                        ? const Icon(
                            Icons.check_rounded,
                            size: 12,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    entry.value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(AppColors.dark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterApplyButton extends StatelessWidget {
  const _FilterApplyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(AppColors.primary),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              const Spacer(),
              const Text(
                'Apply',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFE9FFFC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
