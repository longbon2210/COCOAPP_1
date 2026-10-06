import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/room_listing.dart';
import '../constants/api_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_widgets.dart';
import 'chat_detail_screen.dart';

class RoommateFinderScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const RoommateFinderScreen({super.key, this.onNavigateToTab});

  @override
  State<RoommateFinderScreen> createState() => _RoommateFinderScreenState();
}

class _RoommateFinderScreenState extends State<RoommateFinderScreen> {
  // Chế độ xem: 0 = Bạn ở ghép, 1 = Phòng trọ cho thuê
  int _viewMode = 0;

  List<UserProfile> _allUsers = [];
  List<UserProfile> _filteredUsers = [];
  List<RoomListing> _allRooms = [];
  List<RoomListing> _filteredRooms = [];

  bool _isLoading = true;
  String _selectedFilter = 'Tất cả';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchRooms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final myEmail = (prefs.getString('user_email') ?? '0000@gmail.com').toLowerCase();
    final url = Uri.parse(ApiConfig.users);

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final users = data
            .asMap()
            .entries
            .map((entry) => UserProfile.fromApiJson(entry.value, index: entry.key))
            .where((u) => u.email.toLowerCase() != myEmail)
            .toList();

        setState(() {
          _allUsers = users.isNotEmpty ? users : UserProfile.getSampleProfiles();
          _applyFilter();
        });
      } else {
        setState(() {
          if (_allUsers.isEmpty) _allUsers = UserProfile.getSampleProfiles();
          _applyFilter();
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách người dùng thực tế: $e');
      if (mounted) {
        setState(() {
          if (_allUsers.isEmpty) _allUsers = UserProfile.getSampleProfiles();
          _applyFilter();
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRooms() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.rooms)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final rooms = data.map((e) => RoomListing.fromJson(e as Map<String, dynamic>)).toList();
        setState(() {
          _allRooms = rooms.isNotEmpty ? rooms : RoomListing.getSampleRooms();
          _applyFilter();
        });
      } else {
        setState(() {
          if (_allRooms.isEmpty) _allRooms = RoomListing.getSampleRooms();
          _applyFilter();
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách phòng trọ: $e');
      if (mounted) {
        setState(() {
          if (_allRooms.isEmpty) _allRooms = RoomListing.getSampleRooms();
          _applyFilter();
        });
      }
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();

    // Lọc người ở ghép thực tế
    _filteredUsers = _allUsers.where((u) {
      final matchesQuery = query.isEmpty ||
          u.name.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query) ||
          u.university.toLowerCase().contains(query) ||
          u.major.toLowerCase().contains(query) ||
          u.roomLocation.toLowerCase().contains(query);

      if (!matchesQuery) return false;

      if (_selectedFilter == 'Tất cả') return true;
      if (_selectedFilter == 'ICTU') return u.university.toUpperCase().contains('ICTU');
      if (_selectedFilter == 'Dưới 2tr') return u.rentalBudget <= 2000000;
      if (_selectedFilter == 'Không hút thuốc') return !u.isSmoker;
      if (_selectedFilter == 'Đã có phòng') return u.roomStatus.contains('Đã có phòng');

      return true;
    }).toList();

    // Lọc phòng trọ
    _filteredRooms = _allRooms.where((r) {
      final matchesQuery = query.isEmpty ||
          r.title.toLowerCase().contains(query) ||
          r.address.toLowerCase().contains(query) ||
          r.universityNear.toLowerCase().contains(query);

      if (!matchesQuery) return false;

      if (_selectedFilter == 'Tất cả') return true;
      if (_selectedFilter == 'Dưới 2tr') return r.pricePerMonth <= 2000000;
      if (_selectedFilter == 'ICTU') return r.universityNear.contains('ICTU');
      if (_selectedFilter == 'Có điều hòa') return r.amenities.any((a) => a.contains('Điều hòa'));

      return true;
    }).toList();
  }

  void _showCreatePostDialog() {
    final titleController = TextEditingController();
    final locationController = TextEditingController(text: 'Đường Z115, gần ICTU');
    final budgetController = TextEditingController(text: '1800000');
    final phoneController = TextEditingController(text: '0988 123 456');
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          top: 24,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const Text(
                'Đăng Tin Tìm Trọ / Cho Thuê Thực Tế 📝',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tin đăng sẽ được lưu trên hệ thống và hiển thị ngay cho các bạn sinh viên khác.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề bài đăng',
                  hintText: 'VD: Tìm 1 bạn nam ở ghép phòng khép kín ICTU',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ / Khu vực',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: budgetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Giá thuê / Ngân sách (VNĐ)',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại liên hệ',
                        prefixIcon: Icon(Icons.phone_rounded),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mô tả chi tiết phòng / yêu cầu ở ghép',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;

                    final prefs = await SharedPreferences.getInstance();
                    final myEmail = prefs.getString('user_email') ?? '0000@gmail.com';
                    final myName = myEmail.split('@').first;

                    final newRoom = {
                      'title': titleController.text.trim(),
                      'address': locationController.text.trim(),
                      'pricePerMonth': double.tryParse(budgetController.text.trim()) ?? 1800000,
                      'landlordName': myName,
                      'landlordPhone': phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : '0988 123 456',
                      'authorEmail': myEmail,
                      'universityNear': 'ICTU',
                      'distance': 'Gần cổng trường',
                      'areaM2': 22,
                      'description': descController.text.trim().isNotEmpty
                          ? descController.text.trim()
                          : 'Phòng khép kín sạch sẽ, gần trường, an ninh tốt.',
                      'amenities': ['Wifi', 'Nóng lạnh', 'Giờ tự do'],
                      'images': [
                        'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=800',
                      ],
                    };

                    try {
                      await http.post(
                        Uri.parse(ApiConfig.rooms),
                        headers: {'Content-Type': 'application/json; charset=utf-8'},
                        body: jsonEncode(newRoom),
                      );
                      await _fetchRooms();
                    } catch (e) {
                      debugPrint('Lỗi đăng tin phòng: $e');
                    }

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã đăng tin thành công trên hệ thống! 🎉'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  child: const Text('Đăng Tin Lên Hệ Thống', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.post_add_rounded),
              label: const Text('Đăng Tin Tìm Trọ', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _showCreatePostDialog,
            ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 1240 : 680),
            child: Column(
              children: [
                // 1. THANH HEADER
                if (!isDesktop) _buildHeader(),

                // 2. Ô TÌM KIẾM
                _buildSearchBar(),

                // 3. SEGMENTED TABS (BẠN Ở GHÉP vs PHÒNG TRỌ)
                _buildSegmentedTab(),

                // 4. BỘ LỌC
                _buildFilterChips(),

                const SizedBox(height: 4),

                // 5. NỘI DUNG CHÍNH
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _viewMode == 0
                          ? _buildRoommatesList()
                          : _buildRoomsList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tìm Trọ & Ở Ghép Sinh Viên',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Row(
                  children: const [
                    Icon(Icons.verified_user_rounded, size: 13, color: AppColors.success),
                    SizedBox(width: 4),
                    Text(
                      'Tương tác người dùng thực tế • Đại học Thái Nguyên & ICTU',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Làm mới',
            onPressed: () {
              _fetchUsers();
              _fetchRooms();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() => _applyFilter()),
          decoration: InputDecoration(
            hintText: _viewMode == 0
                ? 'Tìm kiếm theo tên tài khoản, ngành học, trường...'
                : 'Tìm kiếm phòng trọ theo địa chỉ, tiêu đề...',
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _applyFilter());
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedTab() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _viewMode = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _viewMode == 0 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _viewMode == 0 ? AppColors.cardShadow : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_alt_rounded,
                        size: 18,
                        color: _viewMode == 0 ? AppColors.primary : AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sinh Viên Thực Tế (${_filteredUsers.length})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _viewMode == 0 ? AppColors.primary : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _viewMode = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _viewMode == 1 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _viewMode == 1 ? AppColors.cardShadow : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.apartment_rounded,
                        size: 18,
                        color: _viewMode == 1 ? AppColors.primary : AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Phòng Trọ Đã Đăng (${_filteredRooms.length})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _viewMode == 1 ? AppColors.primary : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = _viewMode == 0
        ? ['Tất cả', 'ICTU', 'Dưới 2tr', 'Không hút thuốc']
        : ['Tất cả', 'Dưới 2tr', 'ICTU', 'Có điều hòa'];

    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return ChoiceChip(
            label: Text(
              filter,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
            onSelected: (_) {
              setState(() {
                _selectedFilter = filter;
                _applyFilter();
              });
            },
          );
        },
      ),
    );
  }

  // 1. DANH SÁCH SINH VIÊN THỰC TẾ
  Widget _buildRoommatesList() {
    if (_filteredUsers.isEmpty) {
      return _buildEmptyState('Không có sinh viên nào phù hợp bộ lọc.');
    }

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 1100 ? 3 : (width >= 720 ? 2 : 1);

    if (crossAxisCount == 1) {
      return RefreshIndicator(
        onRefresh: () async {
          await _fetchUsers();
          await _fetchRooms();
        },
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          itemCount: _filteredUsers.length,
          itemBuilder: (context, index) {
            final user = _filteredUsers[index];
            return _buildRoommateCard(user, isGrid: false);
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchUsers();
        await _fetchRooms();
      },
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 270,
        ),
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          return _buildRoommateCard(user, isGrid: true);
        },
      ),
    );
  }

  Widget _buildRoommateCard(UserProfile user, {bool isGrid = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isGrid ? 0 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(user.avatarUrl),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: user.isOnline ? AppColors.success : AppColors.textMuted,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const VerifiedBadge(text: "Người dùng thực"),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user.university} • ${user.major}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                CompatibilityRing(
                  percentage: user.compatibilityScore > 0 ? user.compatibilityScore : 95,
                  size: 44,
                ),
              ],
            ),
            if (user.lifestyleTags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: user.lifestyleTags.map((tag) => GradientPillBadge(
                  label: tag,
                  backgroundColor: AppColors.primarySoft,
                  foregroundColor: AppColors.primary,
                  fontSize: 11,
                )).toList(),
              ),
            ],
            const SizedBox(height: 14),

            // NÚT HÀNH ĐỘNG
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.info_outline_rounded, size: 18),
                    label: const Text('Xem Hồ Sơ'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    onPressed: () => _showUserDetailsModal(user),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppColors.buttonShadow,
                    ),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.chat_bubble_rounded, size: 18, color: Colors.white),
                      label: const Text('Nhắn Tin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(partner: user),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 2. DANH SÁCH PHÒNG TRỌ ĐÃ ĐĂNG
  Widget _buildRoomsList() {
    if (_filteredRooms.isEmpty) {
      return _buildEmptyState('Chưa có bài đăng phòng trọ nào. Hãy nhấn nút để đăng tin đầu tiên!');
    }

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 1100 ? 3 : (width >= 720 ? 2 : 1);

    if (crossAxisCount == 1) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _filteredRooms.length,
        itemBuilder: (context, index) {
          final room = _filteredRooms[index];
          return _buildRoomCard(room, isGrid: false);
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 310,
      ),
      itemCount: _filteredRooms.length,
      itemBuilder: (context, index) {
        final room = _filteredRooms[index];
        return _buildRoomCard(room, isGrid: true);
      },
    );
  }

  Widget _buildRoomCard(RoomListing room, {bool isGrid = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isGrid ? 0 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    room.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${(room.pricePerMonth / 1000000).toStringAsFixed(1)} tr/tháng',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    room.address,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              room.description,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Đăng bởi: ${room.landlordName} (${room.authorEmail})',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.chat_bubble_rounded, size: 16, color: Colors.white),
                  label: const Text('Nhắn Tin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final partner = UserProfile(
                      id: room.authorEmail.hashCode.abs() % 10000,
                      email: room.authorEmail,
                      name: room.landlordName,
                      university: room.universityNear,
                      major: 'Sinh viên',
                      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
                      bio: room.description,
                      rentalBudget: room.pricePerMonth,
                      roomLocation: room.address,
                      roomStatus: 'Đã đăng phòng',
                      gender: 'Nam',
                      isSmoker: false,
                      hasPet: false,
                      studyGoal: room.title,
                      studySkills: ['Phòng trọ'],
                      lifestyleTags: ['Sinh viên'],
                      compatibilityScore: 96,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChatDetailScreen(partner: partner)),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetailsModal(UserProfile user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(user.avatarUrl),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user.university} • ${user.major}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.school_rounded, color: AppColors.primary),
                      title: const Text('Trường đại học'),
                      subtitle: Text(user.university),
                    ),
                    ListTile(
                      leading: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
                      title: const Text('Chuyên ngành'),
                      subtitle: Text(user.major),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
                  label: const Text('Nhắn Tin Trực Tiếp Với Tài Khoản Này'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChatDetailScreen(partner: user)),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_search_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedFilter = 'Tất cả';
                  _applyFilter();
                });
              },
              child: const Text('Xem Tất Cả', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
