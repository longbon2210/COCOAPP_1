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
      // Cho phép truyền query param ?api=https://... trên thanh địa chỉ để tùy chỉnh backend nếu cần
      final qApi = Uri.base.queryParameters['api'];
      if (qApi != null && qApi.isNotEmpty) {
        return qApi;
      }

      final origin = Uri.base.origin;
      if (origin.isNotEmpty && origin != 'null') {
        // Nếu đang chạy thử nghiệm cục bộ trên localhost hoặc 127.0.0.1 (cổng 8080, 5000, hoặc bất kỳ cổng nào)
        if (origin.contains('localhost') || origin.contains('127.0.0.1')) {
          return dotnetLocalUrl; // Luôn kết nối trực tiếp đến Backend .NET API http://localhost:5000
        }
        // Nếu triển khai trên Vercel / Render / Netlify có proxy nội bộ
        if (origin.contains('vercel.app') || origin.contains('onrender.com') || origin.contains('netlify.app')) {
          return origin;
        }
      }
      // Khi truy cập qua link công khai ngoài internet (GitHub Pages, v.v.): Trỏ về Somee Cloud Backend
      return someeUrl;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return androidEmulatorUrl;
    }
    return dotnetLocalUrl;
  }

  /// Kiểm tra xem ứng dụng đang chạy ở môi trường máy cục bộ (Localhost / Android Emulator / Desktop)
  /// hay đang chạy trên Web Cloud công khai (GitHub Pages, etc.)
  static bool get isLocalEnvironment {
    if (!kIsWeb) return true;
    final origin = Uri.base.origin.toLowerCase();
    return origin.contains('localhost') || origin.contains('127.0.0.1');
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
  static String get chatHub => '$baseUrl/chatHub';
  static String get matches => '$baseUrl/api/swipes/matches';
}
