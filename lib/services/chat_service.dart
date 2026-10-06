import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../constants/api_config.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  void _notify() {
    for (final listener in _listeners) {
      listener();
    }
  }

  Future<String> _getMyEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email') ?? '0000@gmail.com';
  }

  // Lấy lịch sử tin nhắn thực tế giữa 2 người dùng qua Server API
  Future<List<ChatMessage>> getMessages(dynamic partnerOrId, {String? partnerEmail}) async {
    final myEmail = await _getMyEmail();
    String targetEmail = partnerEmail ?? '';

    if (targetEmail.isEmpty && partnerOrId is UserProfile) {
      targetEmail = partnerOrId.email;
    }

    if (targetEmail.isEmpty) {
      // Fallback tìm email từ cache nếu chỉ truyền partnerId
      final prefs = await SharedPreferences.getInstance();
      targetEmail = prefs.getString('partner_email_${partnerOrId.toString()}') ?? '';
    }

    if (targetEmail.isEmpty) {
      return [];
    }

    try {
      final url = Uri.parse('${ApiConfig.messages}?user1=${Uri.encodeComponent(myEmail)}&user2=${Uri.encodeComponent(targetEmail)}');
      final res = await http.get(url).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((item) {
          final sEmail = (item['senderEmail'] ?? '').toString();
          final isMe = sEmail.toLowerCase() == myEmail.toLowerCase();
          return ChatMessage(
            id: item['id']?.toString() ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
            senderId: isMe ? 0 : 1,
            receiverId: isMe ? 1 : 0,
            text: item['text']?.toString() ?? '',
            timestamp: DateTime.tryParse(item['timestamp']?.toString() ?? '') ?? DateTime.now(),
            isMe: isMe,
            isRead: item['isRead'] == true,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Lỗi tải tin nhắn từ server: $e');
    }
    return [];
  }

  // Gửi tin nhắn thực tế tới người dùng khác qua Server API (KHÔNG CÓ BOT)
  Future<ChatMessage?> sendMessage({
    required UserProfile partner,
    required String text,
  }) async {
    final myEmail = await _getMyEmail();
    final url = Uri.parse(ApiConfig.messages);

    // Lưu cache email của partner
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('partner_email_${partner.id}', partner.email);

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'senderEmail': myEmail,
          'receiverEmail': partner.email,
          'senderName': myEmail.split('@').first,
          'receiverName': partner.name,
          'text': text,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        final newMsg = ChatMessage(
          id: data['id']?.toString() ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
          senderId: 0,
          receiverId: partner.id,
          text: text,
          timestamp: DateTime.now(),
          isMe: true,
          isRead: true,
        );
        _notify();
        return newMsg;
      }
    } catch (e) {
      debugPrint('Lỗi gửi tin nhắn thực tế: $e');
    }
    return null;
  }

  // Lấy tất cả tin nhắn của tôi từ Server để hiển thị danh sách cuộc trò chuyện
  Future<List<Map<String, dynamic>>> getMyConversations() async {
    final myEmail = await _getMyEmail();
    try {
      final url = Uri.parse('${ApiConfig.messages}?myEmail=${Uri.encodeComponent(myEmail)}');
      final res = await http.get(url).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách cuộc trò chuyện: $e');
    }
    return [];
  }
}
