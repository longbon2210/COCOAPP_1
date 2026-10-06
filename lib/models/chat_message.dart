import 'user_profile.dart';

class ChatMessage {
  final String id;
  final int senderId;
  final int receiverId;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.isRead = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'receiverId': receiverId,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'isMe': isMe,
    'isRead': isRead,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id']?.toString() ?? '',
    senderId: json['senderId'] as int? ?? 0,
    receiverId: json['receiverId'] as int? ?? 0,
    text: json['text']?.toString() ?? '',
    timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    isMe: json['isMe'] == true,
    isRead: json['isRead'] == true,
  );
}

class ChatConversation {
  final UserProfile partner;
  ChatMessage lastMessage;
  int unreadCount;

  ChatConversation({
    required this.partner,
    required this.lastMessage,
    this.unreadCount = 0,
  });
}
