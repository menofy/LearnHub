import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';

import 'package:learnhub/core/navigation/app_routes.dart';

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  final List<String> _digits = <String>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create New Pin',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Add a Pin Number to Make Your Account\nmore Secure',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final hasValue = index < _digits.length;
                return Container(
                  width: 46,
                  height: 46,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      hasValue ? '*' : '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 22),
            EduPrimaryButton(
              label: 'Continue',
              onPressed: _digits.length == 4
                  ? () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.setFingerprint)
                  : null,
            ),
            const Spacer(),
            _PinPad(
              onTap: (digit) {
                setState(() {
                  if (digit == '<') {
                    if (_digits.isNotEmpty) {
                      _digits.removeLast();
                    }
                  } else if (_digits.length < 4) {
                    _digits.add(digit);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PinPad extends StatelessWidget {
  const _PinPad({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final keys = <String>[
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '*',
      '0',
      '<',
    ];

    return GridView.builder(
      shrinkWrap: true,
      itemCount: keys.length,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.3,
      ),
      itemBuilder: (context, index) {
        final key = keys[index];
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onTap(key),
          child: Center(
            child: Text(
              key == '<' ? '⌫' : key,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
          ),
        );
      },
    );
  }
}
