import 'dart:async';

import 'package:flutter/material.dart';
import 'package:learnhub/features/course/providers/course_provider.dart';
import 'package:learnhub/presentation/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

import 'widgets/search_discovery_view.dart';
import 'widgets/search_filter_chips.dart';
import 'widgets/search_header.dart';
import 'widgets/search_query_field.dart';
import 'widgets/search_results_view.dart';

const List<String> _fallbackRecentSearches = <String>[
  '3D Design',
  'Graphic Design',
  'Programming',
  'SEO & Marketing',
  'Web Development',
  'Office Productivity',
  'Personal Development',
  'Finance & Accounting',
  'HR Management',
];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _selectedCategory = 'All';
  String _selectedLevel = 'All Levels';
  CourseSortOption _sort = CourseSortOption.recommended;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CourseProvider>();
      provider.loadCourses(showLoading: false);
      provider.searchCourses('');
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) {
        return;
      }
      context.read<CourseProvider>().searchCourses(value);
    });
    setState(() {});
  }

  void _handleSearchSubmitted(String value) {
    final keyword = value.trim();
    if (keyword.isEmpty) {
      return;
    }
    context.read<AppStateProvider>().addRecentSearch(keyword);
  }

  void _saveCurrentQuery() {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      return;
    }
    context.read<AppStateProvider>().addRecentSearch(keyword);
  }

  void _applyRecentSearch(String keyword) {
    _searchController.text = keyword;
    context.read<CourseProvider>().searchCourses(keyword);
    context.read<AppStateProvider>().addRecentSearch(keyword);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final appState = context.watch<AppStateProvider>();
    final query = _searchController.text.trim();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final secondaryText = colorScheme.onSurface.withValues(alpha: 0.72);
    final categories = <String>['All', ...provider.categories];
    final levels = <String>{
      'All Levels',
      ...provider.courses.map((course) => course.level),
    }.toList(growable: false);
    final visibleResults = provider.queryCourses(
      query: query,
      category: _selectedCategory,
      level: _selectedLevel,
      sort: _sort,
    );
    final recommended = provider.recommendedCourses;

    final recents = appState.recentSearches.isEmpty
        ? _fallbackRecentSearches
        : appState.recentSearches;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Column(
            children: [
              SearchHeader(onBack: () => Navigator.of(context).pop()),
              const SizedBox(height: 10),
              SearchQueryField(
                controller: _searchController,
                onChanged: _handleSearchChanged,
                onSubmitted: _handleSearchSubmitted,
                onActionTap: _saveCurrentQuery,
              ),
              const SizedBox(height: 12),
              SearchFilterChips(
                options: categories,
                selectedValue: _selectedCategory,
                onSelected: (category) =>
                    setState(() => _selectedCategory = category),
              ),
              const SizedBox(height: 10),
              SearchFilterChips(
                options: levels,
                selectedValue: _selectedLevel,
                onSelected: (level) => setState(() => _selectedLevel = level),
              ),
              const SizedBox(height: 10),
              SearchSortChips(
                selectedSort: _sort,
                onSelected: (sortOption) => setState(() => _sort = sortOption),
              ),
              const SizedBox(height: 12),
              if (query.isEmpty)
                Expanded(
                  child: SearchDiscoveryView(
                    recommendedCourses: recommended,
                    recentSearches: recents,
                    isDark: isDark,
                    secondaryText: secondaryText,
                    isBookmarked: provider.isInWishlist,
                    onBookmarkTap: provider.toggleWishlist,
                    onRecentTap: _applyRecentSearch,
                    onRemoveRecent: (item) => context
                        .read<AppStateProvider>()
                        .removeRecentSearch(item),
                    onClearRecents: () =>
                        context.read<AppStateProvider>().clearRecentSearches(),
                  ),
                )
              else
                Expanded(
                  child: SearchResultsView(
                    results: visibleResults,
                    isBookmarked: provider.isInWishlist,
                    onBookmarkTap: provider.toggleWishlist,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
