import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../constants/api_config.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  HubConnection? _hubConnection;
  bool _isSignalRConnected = false;
  bool get isSignalRConnected => _isSignalRConnected;

  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  void _notify() {
    for (final listener in _listeners) {
      listener();
    }
  }

  // Danh sách tin nhắn mới nhận real-time từ SignalR
  final List<ChatMessage> _realtimeCache = [];
  List<ChatMessage> get realtimeCache => List.unmodifiable(_realtimeCache);

  Future<String> _getMyEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email') ?? '0000@gmail.com';
  }

  // Khởi tạo kết nối Real-time SignalR tới ChatHub
  Future<void> initSignalR() async {
    if (_hubConnection != null && _hubConnection!.state == HubConnectionState.Connected) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      final hubUrl = ApiConfig.chatHub;

      _hubConnection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async => token,
            ),
          )
          .withAutomaticReconnect()
          .build();

      _hubConnection!.on('ReceiveChatMessage', _onReceiveChatMessage);
      _hubConnection!.on('ReceiveMessage', _onReceiveMessage);

      _hubConnection!.onreconnecting(({error}) {
        debugPrint('[SignalR Hub] Đang kết nối lại: $error');
        _isSignalRConnected = false;
        _notify();
      });

      _hubConnection!.onreconnected(({connectionId}) {
        debugPrint('[SignalR Hub] Đã kết nối lại thành công ID: $connectionId');
        _isSignalRConnected = true;
        _notify();
      });

      _hubConnection!.onclose(({error}) {
        debugPrint('[SignalR Hub] Ngắt kết nối: $error');
        _isSignalRConnected = false;
        _notify();
      });

      await _hubConnection!.start();
      _isSignalRConnected = true;
      debugPrint('[SignalR Hub] Kết nối thành công tới trạm thời gian thực: $hubUrl');
      _notify();
    } catch (e) {
      debugPrint('[SignalR Hub] Cảnh báo kết nối SignalR: $e. Sẽ tự động dùng HTTP REST.');
      _isSignalRConnected = false;
    }
  }

  void _onReceiveChatMessage(List<Object?>? args) async {
    if (args == null || args.isEmpty) return;
    try {
      final dynamic raw = args[0];
      Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw;
      } else if (raw is String) {
        map = jsonDecode(raw);
      } else {
        map = jsonDecode(jsonEncode(raw));
      }

      final myEmail = await _getMyEmail();
      final sEmail = (map['senderEmail'] ?? map['SenderEmail'] ?? '').toString();
      final text = (map['text'] ?? map['Text'] ?? '').toString();
      final id = (map['id'] ?? map['Id'] ?? 'msg_${DateTime.now().millisecondsSinceEpoch}').toString();
      final isMe = sEmail.toLowerCase() == myEmail.toLowerCase();

      final newMsg = ChatMessage(
        id: id,
        senderId: isMe ? 0 : 1,
        receiverId: isMe ? 1 : 0,
        text: text,
        timestamp: DateTime.tryParse((map['timestamp'] ?? map['Timestamp'] ?? '').toString()) ?? DateTime.now(),
        isMe: isMe,
        isRead: isMe,
      );

      if (!_realtimeCache.any((m) => m.id == newMsg.id)) {
        _realtimeCache.add(newMsg);
      }
      _notify();
    } catch (e) {
      debugPrint('[SignalR] Lỗi phân giải tin nhắn: $e');
    }
  }

  void _onReceiveMessage(List<Object?>? args) {
    if (args == null || args.length < 2) return;
    try {
      final senderId = int.tryParse(args[0].toString()) ?? 1;
      final content = args[1].toString();
      final sentAt = args.length > 2 ? (DateTime.tryParse(args[2].toString()) ?? DateTime.now()) : DateTime.now();

      final newMsg = ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        senderId: senderId,
        receiverId: 0,
        text: content,
        timestamp: sentAt,
        isMe: false,
        isRead: false,
      );

      _realtimeCache.add(newMsg);
      _notify();
    } catch (e) {
      debugPrint('[SignalR] Lỗi nhận tin nhắn ID: $e');
    }
  }

  // Lấy lịch sử tin nhắn thực tế giữa 2 người dùng qua Server API
  Future<List<ChatMessage>> getMessages(dynamic partnerOrId, {String? partnerEmail}) async {
    final myEmail = await _getMyEmail();
    String targetEmail = partnerEmail ?? '';

    if (targetEmail.isEmpty && partnerOrId is UserProfile) {
      targetEmail = partnerOrId.email;
    }

    if (targetEmail.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      targetEmail = prefs.getString('partner_email_${partnerOrId.toString()}') ?? '';
    }

    if (targetEmail.isEmpty) {
      return [];
    }

    try {
      final url = Uri.parse('${ApiConfig.messages}?user1=${Uri.encodeComponent(myEmail)}&user2=${Uri.encodeComponent(targetEmail)}');
      final res = await http.get(url).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        final fetched = list.map((item) {
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

        // Gộp cùng các tin nhắn nhận tức thời qua SignalR
        for (final rt in _realtimeCache) {
          if (!fetched.any((m) => m.id == rt.id || (m.text == rt.text && m.timestamp.difference(rt.timestamp).inSeconds.abs() < 2))) {
            fetched.add(rt);
          }
        }
        fetched.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        return fetched;
      }
    } catch (e) {
      debugPrint('Lỗi tải tin nhắn từ server: $e');
    }

    return _realtimeCache;
  }

  // Gửi tin nhắn thực tế tới người dùng khác qua SignalR và Server API
  Future<ChatMessage?> sendMessage({
    required UserProfile partner,
    required String text,
  }) async {
    final myEmail = await _getMyEmail();
    final url = Uri.parse(ApiConfig.messages);

    // Lưu cache email của partner
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('partner_email_${partner.id}', partner.email);

    // Nếu SignalR đang kết nối, gửi qua Hub trước để tối ưu độ trễ
    if (_hubConnection != null && _hubConnection!.state == HubConnectionState.Connected) {
      try {
        await _hubConnection!.invoke('SendChatMessage', args: [
          myEmail,
          partner.email,
          myEmail.split('@').first,
          partner.name,
          text,
        ]);
      } catch (hubErr) {
        debugPrint('[SignalR] Invoke SendChatMessage lỗi: $hubErr. Đang gửi qua REST API...');
      }
    }

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
      ).timeout(const Duration(seconds: 8));

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
        _realtimeCache.add(newMsg);
        _notify();
        return newMsg;
      }
    } catch (e) {
      debugPrint('Lỗi gửi tin nhắn qua REST API: $e');
    }

    // Local instant feedback nếu server bận
    final localMsg = ChatMessage(
      id: 'local_msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 0,
      receiverId: partner.id,
      text: text,
      timestamp: DateTime.now(),
      isMe: true,
      isRead: true,
    );
    _realtimeCache.add(localMsg);
    _notify();
    return localMsg;
  }

  // Lấy tất cả tin nhắn của tôi từ Server để hiển thị danh sách cuộc trò chuyện
  Future<List<Map<String, dynamic>>> getMyConversations() async {
    final myEmail = await _getMyEmail();
    try {
      final url = Uri.parse('${ApiConfig.messages}?myEmail=${Uri.encodeComponent(myEmail)}');
      final res = await http.get(url).timeout(const Duration(seconds: 8));

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
