import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/json_utils.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Buses
  Future<void> saveBuses(List<Map<String, dynamic>> buses) async {
    await _prefs.setString(AppConstants.busesKey, JsonUtils.encodeList(buses));
  }

  List<Map<String, dynamic>> getBuses() {
    final String busesJson = _prefs.getString(AppConstants.busesKey) ?? '[]';
    return JsonUtils.decodeList(busesJson);
  }

  // Bookings
  Future<void> saveBookings(List<Map<String, dynamic>> bookings) async {
    await _prefs.setString(
      AppConstants.bookingsKey,
      JsonUtils.encodeList(bookings),
    );
  }

  List<Map<String, dynamic>> getBookings() {
    final String bookingsJson =   
        _prefs.getString(AppConstants.bookingsKey) ?? '[]';
    return JsonUtils.decodeList(bookingsJson);
  }

  // Admin Profile
  Future<void> saveAdminProfile(Map<String, dynamic> adminProfile) async {
    await _prefs.setString(
      AppConstants.adminProfileKey,
      JsonUtils.encodeMap(adminProfile),
    );
  }

  Map<String, dynamic> getAdminProfile() {
    final String adminJson =
        _prefs.getString(AppConstants.adminProfileKey) ?? '{}';
    return JsonUtils.decodeMap(adminJson);
  }

  // Clear all data
  Future<void> clearAllData() async {
    await _prefs.clear();
  }

  // Notifications
  Future<void> saveNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    await _prefs.setString(
      'notifications',
      JsonUtils.encodeList(notifications),
    );
  }

  List<Map<String, dynamic>> getNotifications() {
    final String notificationsJson = _prefs.getString('notifications') ?? '[]';
    return JsonUtils.decodeList(notificationsJson);
  }
}
