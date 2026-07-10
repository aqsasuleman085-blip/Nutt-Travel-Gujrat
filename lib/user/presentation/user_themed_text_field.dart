import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// Same letters-only, auto-capitalized formatter already used for
/// Passenger Name / Sender Name elsewhere in this project
/// (see NameInputFormatter in payment_screen.dart) - kept identical so
/// typed names behave the same way everywhere in the app.
class NameOnlyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    text = text.replaceAll(RegExp(r'[^a-zA-Z ]'), '');
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    text = text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Validates a Pakistani mobile number in the local 11-digit format:
/// 03XXXXXXXXX (starts with "03", exactly 11 digits total).
String? validatePakistaniPhone(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Required';
  }
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

  if (digits.length != 11) {
    return 'Must be exactly 11 digits';
  }
  if (!digits.startsWith('03')) {
    return 'Must start with 03 (e.g. 0312xxxxxxx)';
  }
  return null;
}

/// Validates a name field contains only letters/spaces (after the
/// NameOnlyInputFormatter has already stripped invalid characters as the
/// user types, this is a safety-net check for paste/autofill cases).
String? validateNameOnly(String? value, {required String fieldLabel}) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldLabel is required';
  }
  if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value.trim())) {
    return '$fieldLabel can only contain letters';
  }
  return null;
}
