import 'package:flutter/material.dart';
import 'package:learnhub/features/shared/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

import 'package:learnhub/core/navigation/app_routes.dart';
import 'package:learnhub/core/theme/app_colors.dart';
import 'widgets/onboarding_intro_page.dart';
import 'widgets/onboarding_page_indicator.dart';
import 'widgets/onboarding_primary_action_button.dart';
import 'widgets/onboarding_skip_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  final List<_IntroData> _items = const [
    _IntroData(
      'Online Learning',
      'We Provide Courses Online Classes and Pre Recorded Lectures!',
    ),
    _IntroData('Learn from Anytime', 'Booked or Some the Lectures for Future'),
    _IntroData(
      'Get Online Certificate',
      'Analyse your scores and Track your results',
    ),
  ];

  bool get _isLastPage => _page == _items.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _finish() {
    context.read<AppStateProvider>().completeOnboarding();
    Navigator.of(context).pushReplacementNamed(AppRoutes.appEntryGate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(AppColors.bg),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const Spacer(),
                  OnboardingSkipButton(onTap: _finish),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _items.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return OnboardingIntroPage(
                    title: item.title,
                    subtitle: item.subtitle,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
              child: Row(
                children: [
                  OnboardingPageIndicator(
                    pageCount: _items.length,
                    currentPage: _page,
                  ),
                  const Spacer(),
                  OnboardingPrimaryActionButton(
                    label: 'Get Started',
                    compact: !_isLastPage,
                    onTap: _isLastPage ? _finish : _goToNextPage,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _IntroData {
  const _IntroData(this.title, this.subtitle);

  final String title;
  final String subtitle;
}
