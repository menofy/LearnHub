import 'package:flutter/material.dart';

import 'package:learnhub/core/theme/app_colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(AppColors.dark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TermSection(
                        title: 'Condition & Attending',
                        content:
                            'At enim hic etiam dolore. Dulce amarum, leve asperum, prope longe, stare movere, quadratum rotundum. '
                            'At certe gravius. Nullus est igitur cuiusquam dies natalis. Paulum, cum regem Persem captum adduceret, '
                            'eodem flumine invectio?\n\n'
                            'Quare hoc videndum est, possine nobis hoc ratio philosophorum dare. Sed finge non solum cilladium eum, '
                            'qui aliquid improbe faciat, verum etiam praepotentem, ut M. Est autem officium, quod ita factum est, '
                            'ut eius facti probabilis ratio reddi possit.',
                      ),
                      SizedBox(height: 12),
                      _TermSection(
                        title: 'Terms & Use',
                        content:
                            'Ut proverbia non nulla veriora sint quam vestra dogmata. Tamen aberamus a proposito, et, ne longius, '
                            'prossus, inquam, Piso, si ista mala sunt, placet. Omnes enim iucundum motum, quo sensus hilaretur. '
                            'Cum id fugient, re eadem defendunt, quae Peripatetici, verba. Quibusnam praeteritis? Si ii Poterunt '
                            'inde esse dicta, quidem hactenus, iis id dicis, vicimus.\n\n'
                            'Qui ita affectus, beatum esse numquam probabis; igitur neque stultorum quisquam beatus neque sapientium '
                            'non beatus.\n\n'
                            'Dicam, inquam, et quidem discedi causa magis, quam quo te aut Epicurum reprehensum velim. Dolor ergo, '
                            'id est summum malum, metetur semper, etiamsi non ader.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermSection extends StatelessWidget {
  const _TermSection({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(AppColors.dark),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(AppColors.dark),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
