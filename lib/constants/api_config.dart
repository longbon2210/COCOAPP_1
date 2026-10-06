import 'package:flutter/foundation.dart';

/// Cấu hình địa chỉ Server API cho COCO APP
/// Hỗ trợ cả .NET 10 Web API cục bộ (http://localhost:5000), Somee Cloud và Android Emulator
class ApiConfig {
  static const String someeUrl = 'http://cocoapp-api.somee.com';
  static const String dotnetLocalUrl = 'http://localhost:5000';
  static const String androidEmulatorUrl = 'http://10.0.2.2:5000';
  static const String dartMockUrl = 'http://localhost:3000';
  static String? manualOverrideUrl;

  static String get baseUrl {
    if (manualOverrideUrl != null) return manualOverrideUrl!;
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && origin != 'null' && (origin.contains(':5000') || origin.contains(':3000'))) {
        return origin;
      }
      return dotnetLocalUrl;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return androidEmulatorUrl;
    }
    return dotnetLocalUrl;
  }

  // Danh sách các Endpoints kết nối Backend API
  static String get login => '$baseUrl/api/auth/login';
  static String get register => '$baseUrl/api/auth/register';
  static String get profile => '$baseUrl/api/users/profile';
  static String get users => '$baseUrl/api/users';
  static String get swipes => '$baseUrl/api/swipes';
  static String get posts => '$baseUrl/api/posts';
  static String get rooms => '$baseUrl/api/rooms';
  static String get messages => '$baseUrl/api/messages';
  static String get bookings => '$baseUrl/api/bookings';
}
