import 'package:flutter/material.dart';
import 'package:learnhub/features/instructor/screens/instructor_shared.dart';

import '../../../../core/theme/app_colors.dart';

class AddCoursePricingVisibilitySection extends StatelessWidget {
  const AddCoursePricingVisibilitySection({
    super.key,
    required this.isPublished,
    required this.isFree,
    required this.priceController,
    required this.onPublishedChanged,
    required this.onFreeChanged,
  });

  final bool isPublished;
  final bool isFree;
  final TextEditingController priceController;
  final ValueChanged<bool> onPublishedChanged;
  final ValueChanged<bool> onFreeChanged;

  @override
  Widget build(BuildContext context) {
    final titleColor = instructorTitleColor(context);
    final secondaryText = instructorMutedColor(context);
    final isDark = instructorIsDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InstructorSectionHeader(
          title: 'Pricing & Visibility',
          subtitle:
              'Control whether the course is live and how it appears in discovery.',
        ),
        const SizedBox(height: 12),
        InstructorSurfaceCard(
          child: Column(
            children: [
              SwitchListTile(
                value: isPublished,
                contentPadding: EdgeInsets.zero,
                activeThumbColor: const Color(AppColors.primary),
                inactiveTrackColor: isDark
                    ? const Color(0xFF24324B)
                    : const Color(AppColors.line),
                title: Text(
                  'Published',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                  ),
                ),
                subtitle: Text(
                  'Published courses appear in the student app and search results.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: secondaryText,
                  ),
                ),
                onChanged: onPublishedChanged,
              ),
              const Divider(height: 26),
              SwitchListTile(
                value: isFree,
                contentPadding: EdgeInsets.zero,
                activeThumbColor: const Color(AppColors.primary),
                inactiveTrackColor: isDark
                    ? const Color(0xFF24324B)
                    : const Color(AppColors.line),
                title: Text(
                  'Free course',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                  ),
                ),
                subtitle: Text(
                  'Turn this off to assign a price and position the course as premium.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: secondaryText,
                  ),
                ),
                onChanged: onFreeChanged,
              ),
              if (!isFree) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: instructorInputDecoration(
                    context: context,
                    label: 'Price',
                    hint: '99.99',
                    icon: Icons.attach_money_rounded,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
