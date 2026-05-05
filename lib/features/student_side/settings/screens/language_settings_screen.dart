import 'package:flutter/material.dart';
import 'package:learnhub/features/student_side/settings/widgets/language_option_card.dart';
import 'package:learnhub/features/student_side/settings/widgets/language_settings_intro_card.dart';
import 'package:learnhub/features/student_side/settings/widgets/settings_screen_header.dart';
import 'package:learnhub/presentation/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  static const List<_LanguageOptionData> _supportedLanguages =
      <_LanguageOptionData>[
        _LanguageOptionData(
          value: 'English',
          title: 'English',
          nativeTitle: 'English',
          directionLabelEn: 'Left to Right',
          directionLabelAr: 'من اليسار إلى اليمين',
        ),
        _LanguageOptionData(
          value: 'Arabic',
          title: 'Arabic',
          nativeTitle: 'العربية',
          directionLabelEn: 'Right to Left',
          directionLabelAr: 'من اليمين إلى اليسار',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isArabic = appState.isArabic;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsScreenHeader(
                title: isArabic ? 'اللغة' : 'Language',
                subtitle: isArabic
                    ? 'اختر اللغة الحالية للتطبيق.'
                    : 'Choose the language used across the app.',
              ),
              const SizedBox(height: 18),
              LanguageSettingsIntroCard(
                title: isArabic ? 'لغة التطبيق' : 'App Language',
                subtitle: isArabic
                    ? 'يتم تحديث النصوص واتجاه الواجهة المدعوم فورًا.'
                    : 'Supported copy and layout direction update instantly.',
                currentLanguageLabel:
                    '${isArabic ? 'الحالي' : 'Current'}: ${appState.language == 'Arabic' ? 'العربية' : 'English'}',
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: _supportedLanguages.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    if (index == _supportedLanguages.length) {
                      return Text(
                        isArabic
                            ? 'سيتم حفظ اختيارك وتطبيقه مباشرة داخل التطبيق.'
                            : 'Your selection is saved automatically and applied immediately.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.58),
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }

                    final option = _supportedLanguages[index];
                    return LanguageOptionCard(
                      title: option.title,
                      nativeTitle: option.nativeTitle,
                      directionLabel: isArabic
                          ? option.directionLabelAr
                          : option.directionLabelEn,
                      selected: appState.language == option.value,
                      onTap: () => appState.setLanguage(option.value),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOptionData {
  const _LanguageOptionData({
    required this.value,
    required this.title,
    required this.nativeTitle,
    required this.directionLabelEn,
    required this.directionLabelAr,
  });

  final String value;
  final String title;
  final String nativeTitle;
  final String directionLabelEn;
  final String directionLabelAr;
}
