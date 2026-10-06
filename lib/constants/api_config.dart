import 'package:flutter/foundation.dart';

/// Cấu hình địa chỉ Server API cho COCO APP
/// Tự động định tuyến cùng Origin trên Web để triệt tiêu 100% lỗi CORS
class ApiConfig {
  static const String someeUrl = 'http://cocoapp-api.somee.com';
  static const String localBackendUrl = 'http://localhost:3000';
  static String? manualOverrideUrl;

  static String get baseUrl {
    if (manualOverrideUrl != null) return manualOverrideUrl!;
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && origin != 'null' && origin.contains(':3000')) {
        return origin;
      }
      return localBackendUrl;
    }
    return localBackendUrl;
  }

  // Danh sách các Endpoints
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
