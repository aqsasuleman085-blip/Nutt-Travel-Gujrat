import 'package:flutter/services.dart';

/// Same letters-only, auto-capitalized formatter used across this app for
/// any "person name" style field (Passenger Name, Sender Name, Refund
/// Account Name, etc.) - keeps typed names behaving identically wherever
/// they're entered, on both the user and admin sides.
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
/// 03XXXXXXXXX (starts with "03", exactly 11 digits total). Used for any
/// phone/account-number field across the app (user's own phone, JazzCash
/// sender number, admin-entered refund account number, etc.).
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

/// Validates a name field contains only letters/spaces (after
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
