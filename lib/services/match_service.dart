import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../constants/api_config.dart';

class MatchService {
  static final MatchService _instance = MatchService._internal();
  factory MatchService() => _instance;
  MatchService._internal();

  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  void _notify() {
    for (final listener in _listeners) {
      listener();
    }
  }

  // Lấy User ID của tài khoản đang đăng nhập
  Future<int> _getMyUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');
    if (id != null && id > 0) return id;

    // Fallback nếu chưa lưu user_id: xác định theo email hoặc mặc định 4 (Tài khoản demo)
    final email = prefs.getString('user_email') ?? '';
    if (email.contains('nam.nh')) return 1;
    if (email.contains('trang.tt')) return 2;
    if (email.contains('quan.lv')) return 3;
    return 4;
  }

  // Ghi nhận quẹt thẻ và xác định Tương Hợp qua Backend API thực tế (Không dùng fake % 4)
  Future<Map<String, dynamic>> recordSwipeDetailed({
    required UserProfile user,
    required bool isLike,
    bool isSuperLike = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final myUserId = await _getMyUserId();
    final token = prefs.getString('jwt_token');

    // Lưu cục bộ lượt quẹt vào cache để tối ưu trải nghiệm
    if (!isLike) {
      final passedList = prefs.getStringList('passed_user_ids') ?? [];
      if (!passedList.contains(user.id.toString())) {
        passedList.add(user.id.toString());
        await prefs.setStringList('passed_user_ids', passedList);
      }
    } else {
      final likedList = prefs.getStringList('liked_user_ids') ?? [];
      if (!likedList.contains(user.id.toString())) {
        likedList.add(user.id.toString());
        await prefs.setStringList('liked_user_ids', likedList);
      }
    }

    bool isMatch = false;
    String message = isLike ? "Đã thích hồ sơ!" : "Đã bỏ qua hồ sơ.";

    try {
      final url = Uri.parse(ApiConfig.swipes);
      final headers = {
        'Content-Type': 'application/json; charset=utf-8',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };
      final body = jsonEncode({
        'swiperId': myUserId,
        'targetUserId': user.id,
        'isLike': isLike,
      });

      final response = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        isMatch = data['isMatch'] == true;
        if (data['message'] != null) {
          message = data['message'].toString();
        }
      }
    } catch (e) {
      debugPrint("Lỗi gọi Swipe API thực tế: $e");
    }

    // Nếu Backend xác nhận Tương Hợp (Match thành công 2 chiều), cập nhật danh sách bạn bè đã Match
    if (isMatch) {
      final matchedProfiles = await getMatchedUsers();
      final alreadyExists = matchedProfiles.any((m) => m.id == user.id || m.email.toLowerCase() == user.email.toLowerCase());
      if (!alreadyExists) {
        matchedProfiles.insert(0, user);
        final jsonList = matchedProfiles.map((m) => jsonEncode(m.toJson())).toList();
        await prefs.setStringList('matched_users_data', jsonList);
      }
      _notify();
    }

    return {
      'isMatch': isMatch,
      'message': message,
    };
  }

  // Tương thích ngược: trả về boolean
  Future<bool> recordSwipe({
    required UserProfile user,
    required bool isLike,
    bool isSuperLike = false,
  }) async {
    final result = await recordSwipeDetailed(user: user, isLike: isLike, isSuperLike: isSuperLike);
    return result['isMatch'] == true;
  }

  // Lấy danh sách bạn bè đã tương hợp thành công từ Backend API
  Future<List<UserProfile>> getMatchedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final myUserId = await _getMyUserId();
    final token = prefs.getString('jwt_token');

    try {
      final url = Uri.parse('${ApiConfig.swipes}/matches/$myUserId');
      final headers = {
        'Content-Type': 'application/json; charset=utf-8',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        final users = list
            .asMap()
            .entries
            .map((e) => UserProfile.fromApiJson(e.value, index: e.key))
            .toList();

        if (users.isNotEmpty) {
          final jsonList = users.map((u) => jsonEncode(u.toJson())).toList();
          await prefs.setStringList('matched_users_data', jsonList);
          return users;
        }
      }
    } catch (e) {
      debugPrint("Lỗi tải danh sách Matches từ backend: $e");
    }

    // Fallback nếu mất mạng hoặc offline: đọc từ cache SharedPreferences
    final jsonList = prefs.getStringList('matched_users_data') ?? [];
    return jsonList.map((str) {
      try {
        final Map<String, dynamic> map = jsonDecode(str);
        return UserProfile.fromJson(map);
      } catch (_) {
        return null;
      }
    }).whereType<UserProfile>().toList();
  }

  // Đồng bộ khởi tạo nếu cần
  Future<void> ensureInitialMatches(List<UserProfile> available) async {
    final current = await getMatchedUsers();
    if (current.isEmpty && available.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final initial = available.take(2).toList();
      final jsonList = initial.map((m) => jsonEncode(m.toJson())).toList();
      await prefs.setStringList('matched_users_data', jsonList);
    }
  }
}
