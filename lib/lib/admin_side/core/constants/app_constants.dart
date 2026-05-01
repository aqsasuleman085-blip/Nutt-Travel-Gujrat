import 'package:flutter/material.dart';

class AppConstants {
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color darkGreen = Color(0xFF1B5E20);

  static const String busesKey = 'buses';
  static const String bookingsKey = 'bookings';
  static const String adminProfileKey = 'admin_profile';

  static const String defaultAdminName = 'Admin User';
  static const String defaultAdminEmail = 'admin@busmanagement.com';

  static const List<String> busStatus = ['Active', 'Inactive', 'Maintenance'];
  static const List<String> bookingStatus = ['pending', 'approved', 'rejected'];

  static const double defaultPadding = 16.0;
  static const double cardRadius = 12.0;
  static const double buttonRadius = 8.0;
}
