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

  Future<String> _getMyEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email') ?? '0000@gmail.com';
  }

  Future<String> _getMyName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name') ?? 'Tôi';
  }

  String _convoKey(String email1, String email2) {
    final e1 = email1.trim().toLowerCase();
    final e2 = email2.trim().toLowerCase();
    final list = [e1, e2]..sort();
    return 'coco_chat_${list[0]}_${list[1]}';
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

      final myEmail = (await _getMyEmail()).toLowerCase();
      final sEmail = (map['senderEmail'] ?? map['SenderEmail'] ?? '').toString().toLowerCase();
      final rEmail = (map['receiverEmail'] ?? map['ReceiverEmail'] ?? '').toString().toLowerCase();
      final text = (map['text'] ?? map['Text'] ?? '').toString();
      final id = (map['id'] ?? map['Id'] ?? 'msg_${DateTime.now().millisecondsSinceEpoch}').toString();
      final timestamp = DateTime.tryParse((map['timestamp'] ?? map['Timestamp'] ?? '').toString()) ?? DateTime.now();

      // Chỉ xử lý tin nhắn liên quan đến tài khoản hiện tại
      if (sEmail != myEmail && rEmail != myEmail) {
        return;
      }

      final isMe = sEmail == myEmail;
      final partnerEmail = isMe ? rEmail : sEmail;

      final incomingMsg = ChatMessage(
        id: id,
        senderId: isMe ? 0 : 1,
        receiverId: isMe ? 1 : 0,
        senderEmail: sEmail,
        receiverEmail: rEmail,
        senderName: (map['senderName'] ?? map['SenderName'] ?? '').toString(),
        receiverName: (map['receiverName'] ?? map['ReceiverName'] ?? '').toString(),
        text: text,
        timestamp: timestamp,
        isMe: isMe,
        isRead: isMe,
      );

      // Lưu ngay vào SharedPreferences
      await _saveMessageLocally(myEmail, partnerEmail, incomingMsg);
      _notify();
    } catch (e) {
      debugPrint('[SignalR] Lỗi phân giải tin nhắn: $e');
    }
  }

  void _onReceiveMessage(List<Object?>? args) async {
    if (args == null || args.length < 2) return;
    try {
      final senderId = int.tryParse(args[0].toString()) ?? 1;
      final content = args[1].toString();
      final sentAt = args.length > 2 ? (DateTime.tryParse(args[2].toString()) ?? DateTime.now()) : DateTime.now();
      final myEmail = await _getMyEmail();

      final incomingMsg = ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        senderId: senderId,
        receiverId: 0,
        text: content,
        timestamp: sentAt,
        isMe: false,
        isRead: false,
      );

      final prefs = await SharedPreferences.getInstance();
      final partnerEmail = prefs.getString('partner_email_$senderId') ?? 'partner_$senderId@cocoapp.vn';
      await _saveMessageLocally(myEmail, partnerEmail, incomingMsg);
      _notify();
    } catch (e) {
      debugPrint('[SignalR] Lỗi nhận tin nhắn ID: $e');
    }
  }

  Future<void> _saveMessageLocally(String myEmail, String partnerEmail, ChatMessage msg) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _convoKey(myEmail, partnerEmail);
    final listJson = prefs.getStringList(key) ?? [];

    // Kiểm tra trùng lặp
    bool exists = false;
    for (final str in listJson) {
      try {
        final m = jsonDecode(str);
        if (m['id'] == msg.id || (m['text'] == msg.text && (DateTime.tryParse(m['timestamp'])?.difference(msg.timestamp).inSeconds.abs() ?? 10) < 2)) {
          exists = true;
          break;
        }
      } catch (_) {}
    }

    if (!exists) {
      listJson.add(jsonEncode(msg.toJson()));
      await prefs.setStringList(key, listJson);
    }
  }

  // Lấy lịch sử tin nhắn thực tế giữa 2 người dùng qua Bộ nhớ cục bộ & Server API
  Future<List<ChatMessage>> getMessages(dynamic partnerOrId, {String? partnerEmail}) async {
    final myEmail = (await _getMyEmail()).toLowerCase();
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

    targetEmail = targetEmail.toLowerCase();
    final key = _convoKey(myEmail, targetEmail);
    final prefs = await SharedPreferences.getInstance();

    // 1. Đọc tin nhắn từ SharedPreferences trước
    final localListJson = prefs.getStringList(key) ?? [];
    final List<ChatMessage> localMessages = [];
    for (final str in localListJson) {
      try {
        localMessages.add(ChatMessage.fromJson(jsonDecode(str)));
      } catch (_) {}
    }

    // 2. Thử đồng bộ từ Server API
    try {
      final url = Uri.parse('${ApiConfig.messages}?user1=${Uri.encodeComponent(myEmail)}&user2=${Uri.encodeComponent(targetEmail)}');
      final res = await http.get(url).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        for (final item in list) {
          final sEmail = (item['senderEmail'] ?? '').toString().toLowerCase();
          final isMe = sEmail == myEmail;
          final msg = ChatMessage(
            id: item['id']?.toString() ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
            senderId: isMe ? 0 : 1,
            receiverId: isMe ? 1 : 0,
            senderEmail: sEmail,
            receiverEmail: (item['receiverEmail'] ?? '').toString().toLowerCase(),
            senderName: (item['senderName'] ?? '').toString(),
            receiverName: (item['receiverName'] ?? '').toString(),
            text: item['text']?.toString() ?? '',
            timestamp: DateTime.tryParse(item['timestamp']?.toString() ?? '') ?? DateTime.now(),
            isMe: isMe,
            isRead: item['isRead'] == true,
          );

          if (!localMessages.any((m) => m.id == msg.id || (m.text == msg.text && m.timestamp.difference(msg.timestamp).inSeconds.abs() < 2))) {
            localMessages.add(msg);
          }
        }

        // Cập nhật lại cache cục bộ
        localMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        await prefs.setStringList(key, localMessages.map((m) => jsonEncode(m.toJson())).toList());
      }
    } catch (e) {
      debugPrint('Lỗi tải tin nhắn từ server: $e');
    }

    localMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return localMessages;
  }

  // Gửi tin nhắn thực tế tới người dùng khác qua SignalR và Server API
  Future<ChatMessage> sendMessage({
    required UserProfile partner,
    required String text,
  }) async {
    final myEmail = await _getMyEmail();
    final myName = await _getMyName();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('partner_email_${partner.id}', partner.email);

    final newMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 0,
      receiverId: partner.id,
      senderEmail: myEmail,
      receiverEmail: partner.email,
      senderName: myName,
      receiverName: partner.name,
      text: text,
      timestamp: DateTime.now(),
      isMe: true,
      isRead: true,
    );

    // 1. Lưu ngay vào SharedPreferences (Optimistic Local UI Update)
    await _saveMessageLocally(myEmail, partner.email, newMsg);
    _notify();

    // 2. Gửi qua SignalR Hub nếu đang kết nối
    if (_hubConnection != null && _hubConnection!.state == HubConnectionState.Connected) {
      try {
        await _hubConnection!.invoke('SendChatMessage', args: [
          myEmail,
          partner.email,
          myName,
          partner.name,
          text,
        ]);
      } catch (hubErr) {
        debugPrint('[SignalR] Invoke SendChatMessage lỗi: $hubErr. Đang gửi qua REST API...');
      }
    }

    // 3. Gửi qua REST API
    try {
      final url = Uri.parse(ApiConfig.messages);
      await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'id': newMsg.id,
          'senderEmail': myEmail,
          'receiverEmail': partner.email,
          'senderName': myName,
          'receiverName': partner.name,
          'text': text,
          'timestamp': newMsg.timestamp.toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Lỗi gửi tin nhắn qua REST API: $e');
    }

    return newMsg;
  }

  // Lấy tất cả tin nhắn của tôi từ Server & Cục bộ để hiển thị danh sách cuộc trò chuyện
  Future<List<Map<String, dynamic>>> getMyConversations() async {
    final myEmail = (await _getMyEmail()).toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> allMessages = [];

    // 1. Quét các tin nhắn đã lưu cục bộ trong SharedPreferences
    final allKeys = prefs.getKeys();
    for (final key in allKeys) {
      if (key.startsWith('coco_chat_') && key.contains(myEmail)) {
        final listJson = prefs.getStringList(key) ?? [];
        for (final str in listJson) {
          try {
            allMessages.add(jsonDecode(str));
          } catch (_) {}
        }
      }
    }

    // 2. Thử lấy thêm từ Server API
    try {
      final url = Uri.parse('${ApiConfig.messages}?myEmail=${Uri.encodeComponent(myEmail)}');
      final res = await http.get(url).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        for (final item in list) {
          final id = item['id']?.toString() ?? '';
          if (!allMessages.any((m) => m['id'] == id)) {
            allMessages.add(item as Map<String, dynamic>);
          }
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách cuộc trò chuyện: $e');
    }

    return allMessages;
  }
}
