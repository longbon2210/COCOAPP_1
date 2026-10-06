import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class MatchService {
  static final MatchService _instance = MatchService._internal();
  factory MatchService() => _instance;
  MatchService._internal();

  // Ghi nhận quẹt thẻ và xác định Tương Hợp
  Future<bool> recordSwipe({
    required UserProfile user,
    required bool isLike,
    bool isSuperLike = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (!isLike) {
      // Bỏ qua (Pass)
      final passedList = prefs.getStringList('passed_user_ids') ?? [];
      if (!passedList.contains(user.id.toString())) {
        passedList.add(user.id.toString());
        await prefs.setStringList('passed_user_ids', passedList);
      }
      return false;
    }

    // Đã thích (Like hoặc SuperLike)
    final likedList = prefs.getStringList('liked_user_ids') ?? [];
    if (!likedList.contains(user.id.toString())) {
      likedList.add(user.id.toString());
      await prefs.setStringList('liked_user_ids', likedList);
    }

    // Tỉ lệ ghép đôi: SuperLike 100%, Like thường 75% tạo tương hợp
    final bool isMatch = isSuperLike || (user.id % 4 != 0);

    if (isMatch) {
      final matchedProfiles = await getMatchedUsers();
      final alreadyExists = matchedProfiles.any((m) => m.id == user.id);
      if (!alreadyExists) {
        matchedProfiles.insert(0, user);
        final jsonList = matchedProfiles.map((m) => jsonEncode(m.toJson())).toList();
        await prefs.setStringList('matched_users_data', jsonList);
      }
    }

    return isMatch;
  }

  // Lấy danh sách bạn bè đã tương hợp thành công
  Future<List<UserProfile>> getMatchedUsers() async {
    final prefs = await SharedPreferences.getInstance();
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

  // Khởi tạo một số bạn bè mẫu đã tương hợp nếu chưa có
  Future<void> ensureInitialMatches(List<UserProfile> available) async {
    final current = await getMatchedUsers();
    if (current.isEmpty && available.isNotEmpty) {
      final initial = available.take(4).toList();
      final prefs = await SharedPreferences.getInstance();
      final jsonList = initial.map((m) => jsonEncode(m.toJson())).toList();
      await prefs.setStringList('matched_users_data', jsonList);
    }
  }
}
