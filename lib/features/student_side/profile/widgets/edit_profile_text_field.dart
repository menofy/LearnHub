import 'package:flutter/material.dart';

class EditProfileTextField extends StatelessWidget {
  const EditProfileTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.prefix,
    this.readOnly = false,
    this.enabled = true,
    this.validator,
    this.textInputAction,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final IconData? prefix;
  final bool readOnly;
  final bool enabled;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      enabled: enabled,
      validator: validator,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefix == null ? null : Icon(prefix, size: 16),
        filled: readOnly,
        fillColor: readOnly
            ? (isDark ? const Color(0xFF111E34) : const Color(0xFFF5F5F5))
            : null,
      ),
    );
  }
}
