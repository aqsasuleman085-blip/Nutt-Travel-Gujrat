import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Re-exported so existing screens that import this file for
// NameOnlyInputFormatter / validatePakistaniPhone / validateNameOnly keep
// working unchanged - the actual definitions now live in
// lib/shared/validators.dart so both user and admin side screens can use
// them without a cross-folder import.
export '../../shared/validators.dart';

/// A text field styled to match the rest of the user-side screens
/// (tickets_screen.dart, payment_screen.dart) - same emerald theme color,
/// same field height/padding/border-radius as the admin-side
/// CustomTextField this project already uses, just recolored so it's
/// visually consistent on the user side instead of showing the admin's
/// dark green focus border.
class UserThemedTextField extends StatelessWidget {
  static const Color themeColor = Color(0xff10B981);

  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  const UserThemedTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.inputFormatters,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    List<TextInputFormatter> effectiveFormatters = inputFormatters ?? [];
    if (keyboardType == TextInputType.number &&
        !effectiveFormatters.contains(FilteringTextInputFormatter.digitsOnly)) {
      effectiveFormatters = [
        ...effectiveFormatters,
        FilteringTextInputFormatter.digitsOnly,
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters:
              effectiveFormatters.isEmpty ? null : effectiveFormatters,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: themeColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}
