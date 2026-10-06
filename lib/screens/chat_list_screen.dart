import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_config.dart';
import '../models/user_profile.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/match_service.dart';
import '../theme/app_colors.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  final VoidCallback? onExploreTap;

  const ChatListScreen({super.key, this.onExploreTap});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final MatchService _matchService = MatchService();
  final TextEditingController _searchController = TextEditingController();

  List<UserProfile> _matchedUsers = [];
  List<ChatConversation> _conversations = [];
  List<UserProfile> _cachedUsers = [];
  bool _isLoading = true;
  String _searchQuery = "";
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _chatService.addListener(_onServiceUpdate);
    _matchService.addListener(_onServiceUpdate);
    _chatService.initSignalR();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _chatService.removeListener(_onServiceUpdate);
    _matchService.removeListener(_onServiceUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final myEmail = (prefs.getString('user_email') ?? '0000@gmail.com').toLowerCase();

    // 1. Lấy danh sách người dùng (dùng cache hoặc gọi cục bộ nhanh)
    List<UserProfile> realUsers = _cachedUsers;
    if (realUsers.isEmpty) {
      try {
        final res = await http.get(Uri.parse(ApiConfig.users)).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final List<dynamic> data = jsonDecode(res.body);
          realUsers = data
              .asMap()
              .entries
              .map((entry) => UserProfile.fromApiJson(entry.value, index: entry.key))
              .where((u) => u.email.toLowerCase() != myEmail)
              .toList();
        }
      } catch (_) {}

      if (realUsers.isEmpty) {
        realUsers = UserProfile.getSampleProfiles().where((u) => u.email.toLowerCase() != myEmail).toList();
      }
      _cachedUsers = realUsers;
    }

    // 2. Lấy tất cả tin nhắn thực tế của tài khoản tôi từ Server
    final rawMessages = await _chatService.getMyConversations();

    // Gom nhóm tin nhắn theo email của người trò chuyện cùng
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final m in rawMessages) {
      final s = (m['senderEmail'] ?? '').toString().toLowerCase();
      final r = (m['receiverEmail'] ?? '').toString().toLowerCase();
      final partnerEmail = s == myEmail ? r : s;
      if (partnerEmail.isNotEmpty) {
        grouped.putIfAbsent(partnerEmail, () => []).add(m);
      }
    }

    final convos = <ChatConversation>[];
    for (final entry in grouped.entries) {
      final partnerEmail = entry.key;
      final msgs = entry.value;

      final partner = realUsers.firstWhere(
        (u) => u.email.toLowerCase() == partnerEmail,
        orElse: () => UserProfile(
          id: partnerEmail.hashCode.abs() % 10000,
          email: partnerEmail,
          name: partnerEmail.split('@').first,
          university: 'ICTU',
          major: 'Sinh viên',
          avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
          bio: 'Sinh viên đang học tập tại Thái Nguyên',
          rentalBudget: 1800000,
          roomLocation: 'Thái Nguyên',
          roomStatus: 'Đang tìm bạn',
          gender: 'Nam',
          isSmoker: false,
          hasPet: false,
          studyGoal: 'Kết nối bạn học',
          studySkills: ['Học tập'],
          lifestyleTags: ['Gọn gàng'],
          compatibilityScore: 95,
        ),
      );

      final lastRaw = msgs.last;
      final isMe = (lastRaw['senderEmail'] ?? '').toString().toLowerCase() == myEmail;
      final lastMsg = ChatMessage(
        id: lastRaw['id']?.toString() ?? '',
        senderId: isMe ? 0 : 1,
        receiverId: isMe ? 1 : 0,
        text: lastRaw['text']?.toString() ?? '',
        timestamp: DateTime.tryParse(lastRaw['timestamp']?.toString() ?? '') ?? DateTime.now(),
        isMe: isMe,
        isRead: lastRaw['isRead'] == true,
      );

      final unreadCount = msgs.where((m) => (m['senderEmail'] ?? '').toString().toLowerCase() != myEmail && m['isRead'] != true).length;

      convos.add(ChatConversation(
        partner: partner,
        lastMessage: lastMsg,
        unreadCount: unreadCount,
      ));
    }

    // Sắp xếp cuộc trò chuyện có tin nhắn mới nhất lên đầu
    convos.sort((a, b) => b.lastMessage.timestamp.compareTo(a.lastMessage.timestamp));

    // Lấy danh sách bạn bè đã MATCH THỰC TẾ từ Backend API qua MatchService (KHÔNG fake %4)
    final realMatched = await _matchService.getMatchedUsers();

    if (mounted) {
      setState(() {
        _matchedUsers = realMatched;
        _conversations = convos;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredConvos = _conversations.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.partner.name.toLowerCase().contains(q) ||
          c.partner.university.toLowerCase().contains(q) ||
          c.partner.major.toLowerCase().contains(q) ||
          c.lastMessage.text.toLowerCase().contains(q);
    }).toList();

    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('Tin Nhắn Mới', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _showStartNewChatDialog,
      ),
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('Tin Nhắn & Kết Nối'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_comment_outlined),
                  tooltip: 'Bắt đầu trò chuyện mới',
                  onPressed: _showStartNewChatDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Làm mới',
                  onPressed: _loadData,
                ),
              ],
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 980 : 680),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      // THANH TÌM KIẾM
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppColors.cardShadow,
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm bạn cùng phòng, tin nhắn...',
                              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // HÀNG BẠN BÈ ĐÃ KẾT NỐI
                      if (_matchedUsers.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Bạn Bè Đã Kết Nối',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_matchedUsers.length} người bạn',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 106,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: _matchedUsers.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 14),
                            itemBuilder: (context, index) {
                              final user = _matchedUsers[index];
                              return GestureDetector(
                                onTap: () => _openChat(user),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: AppColors.primaryGradient,
                                      ),
                                      child: CircleAvatar(
                                        radius: 30,
                                        backgroundImage: NetworkImage(user.avatarUrl),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: 68,
                                      child: Text(
                                        user.name.split(' ').last,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(indent: 16, endIndent: 16),
                        const SizedBox(height: 8),
                      ],

                      // DANH SÁCH CUỘC TRÒ CHUYỆN (MESSAGES)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Cuộc Trò Chuyện',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),

                      if (filteredConvos.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primarySoft,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 48,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Chưa có cuộc trò chuyện nào',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Hãy kết nối với bạn cùng phòng hoặc tham gia nhóm học tập để bắt đầu trò chuyện nhé!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.home_work_rounded, size: 18),
                                  label: const Text('Tìm Bạn Ở Ghép & Học Tập'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: widget.onExploreTap,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...filteredConvos.map((convo) => _buildConversationTile(convo)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildConversationTile(ChatConversation convo) {
    final hasUnread = convo.unreadCount > 0;
    final partner = convo.partner;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hasUnread ? AppColors.primaryContainer : AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: NetworkImage(partner.avatarUrl),
            ),
            if (partner.isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                partner.name,
                style: TextStyle(
                  fontWeight: hasUnread ? FontWeight.w800 : FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                partner.university,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            convo.lastMessage.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
              color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatDate(convo.lastMessage.timestamp),
              style: TextStyle(
                fontSize: 11,
                color: hasUnread ? AppColors.primary : AppColors.textMuted,
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (hasUnread) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  convo.unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        onTap: () => _openChat(partner),
      ),
    );
  }

  void _openChat(UserProfile partner) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(partner: partner),
      ),
    ).then((_) => _loadData());
  }

  void _showStartNewChatDialog() {
    String searchFilter = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final availableUsers = _cachedUsers.where((u) {
            if (searchFilter.isEmpty) return true;
            final q = searchFilter.toLowerCase();
            return u.name.toLowerCase().contains(q) ||
                u.university.toLowerCase().contains(q) ||
                u.major.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q);
          }).toList();

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.82,
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.forum_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bắt Đầu Cuộc Trò Chuyện',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          Text(
                            'Chọn sinh viên để kết nối và trao đổi ngay',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (val) => setSheetState(() => searchFilter = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên, ngành, trường học...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: availableUsers.isEmpty
                      ? const Center(
                          child: Text(
                            'Không tìm thấy sinh viên phù hợp.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      : ListView.separated(
                          itemCount: availableUsers.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final user = availableUsers[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(user.avatarUrl),
                              ),
                              title: Text(
                                user.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              subtitle: Text(
                                '${user.major} • ${user.university}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _openChat(user);
                                },
                                child: const Text('Nhắn tin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inMinutes < 60) {
      final mins = now.difference(dt).inMinutes;
      return mins <= 1 ? 'Vừa xong' : '$mins p';
    }
    if (now.day == dt.day && now.month == dt.month && now.year == dt.year) {
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$hour:$min';
    }
    return '${dt.day}/${dt.month}';
  }
}
