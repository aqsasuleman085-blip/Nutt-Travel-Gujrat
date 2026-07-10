import 'package:flutter/material.dart';

/// Shows a date picker themed to match this project's emerald color scheme
/// (same 0xff10B981 used throughout the user side) and rounded-card look,
/// instead of Flutter's default blue Material date picker.
Future<DateTime?> showThemedDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  const themeColor = Color(0xff10B981);

  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: themeColor, // header background + selected day
            onPrimary: Colors.white, // header text + selected day text
            onSurface: Colors.black87, // calendar body text
            surface: Colors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: themeColor),
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: Colors.white,
            headerBackgroundColor: themeColor,
            headerForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            todayBorder: const BorderSide(color: themeColor, width: 1.5),
            dayShape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            yearShape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}
