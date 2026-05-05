import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SignupOtpPinPad extends StatelessWidget {
  const SignupOtpPinPad({
    super.key,
    required this.onKeyTap,
    this.enabled = true,
  });

  static const String backspaceValue = '_backspace';

  final ValueChanged<String> onKeyTap;
  final bool enabled;

  static const List<_SignupOtpPadKey> _keys = <_SignupOtpPadKey>[
    _SignupOtpPadKey(label: '1', value: '1'),
    _SignupOtpPadKey(label: '2', value: '2'),
    _SignupOtpPadKey(label: '3', value: '3'),
    _SignupOtpPadKey(label: '4', value: '4'),
    _SignupOtpPadKey(label: '5', value: '5'),
    _SignupOtpPadKey(label: '6', value: '6'),
    _SignupOtpPadKey(label: '7', value: '7'),
    _SignupOtpPadKey(label: '8', value: '8'),
    _SignupOtpPadKey(label: '9', value: '9'),
    _SignupOtpPadKey.spacer(),
    _SignupOtpPadKey(label: '0', value: '0'),
    _SignupOtpPadKey.icon(icon: Icons.backspace_outlined, value: backspaceValue),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.28,
      ),
      itemBuilder: (context, index) {
        final key = _keys[index];
        if (key.isSpacer) {
          return const SizedBox.shrink();
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: enabled ? () => onKeyTap(key.value!) : null,
            child: Ink(
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? colorScheme.outline.withValues(alpha: 0.6)
                      : const Color(AppColors.line),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: key.icon != null
                    ? Icon(
                        key.icon,
                        size: 24,
                        color: colorScheme.onSurface,
                      )
                    : Text(
                        key.label!,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SignupOtpPadKey {
  const _SignupOtpPadKey({required this.label, required this.value})
    : icon = null,
      isSpacer = false;

  const _SignupOtpPadKey.spacer()
    : label = null,
      icon = null,
      value = null,
      isSpacer = true;

  const _SignupOtpPadKey.icon({required IconData this.icon, required this.value})
    : label = null,
      isSpacer = false;

  final String? label;
  final IconData? icon;
  final String? value;
  final bool isSpacer;
}
