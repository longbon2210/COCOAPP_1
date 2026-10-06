import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/study_post.dart';
import '../models/study_material.dart';
import '../models/user_profile.dart';
import '../constants/api_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_widgets.dart';
import 'chat_detail_screen.dart';

class StudyHubScreen extends StatefulWidget {
  const StudyHubScreen({super.key});

  @override
  State<StudyHubScreen> createState() => _StudyHubScreenState();
}

class _StudyHubScreenState extends State<StudyHubScreen> {
  int _activeTab = 0; // 0 = Nhóm học tập, 1 = Kho tài liệu

  List<StudyPost> _posts = [];
  List<StudyMaterial> _materials = [];

  String _selectedCategory = 'Tất cả';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingPosts = true;
  String _userEmail = '0000@gmail.com';

  @override
  void initState() {
    super.initState();
    _loadUserSession();
    _fetchPosts();
    _materials = StudyMaterial.getSampleMaterials();
  }

  Future<void> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email != null && email.isNotEmpty) {
      if (mounted) setState(() => _userEmail = email);
    }
  }

  Future<void> _deletePost(StudyPost post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Xóa Bài Đăng Nhóm?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn xóa bài đăng "${post.title}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await http.delete(Uri.parse('${ApiConfig.posts}?id=${post.id}'));
        if (res.statusCode == 200) {
          _fetchPosts();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã xóa bài đăng thành công!'), backgroundColor: AppColors.success),
            );
          }
        }
      } catch (e) {
        debugPrint('Lỗi xóa bài đăng: $e');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoadingPosts = true);
    try {
      final res = await http.get(Uri.parse(ApiConfig.posts)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final loaded = data.map((e) => StudyPost.fromJson(e as Map<String, dynamic>)).toList();
        setState(() {
          _posts = loaded.isNotEmpty ? loaded : StudyPost.getSamplePosts();
        });
      } else {
        setState(() {
          if (_posts.isEmpty) _posts = StudyPost.getSamplePosts();
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải bài đăng học tập từ server: $e');
      if (mounted) {
        setState(() {
          if (_posts.isEmpty) _posts = StudyPost.getSamplePosts();
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingPosts = false);
    }
  }

  void _showCreatePostDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final subjectController = TextEditingController(text: 'Đồ án tốt nghiệp');
    int needed = 3;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.group_add_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Đăng Tin Tìm Bạn Học Thực Tế', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề bài đăng',
                      hintText: 'VD: Cần 2 bạn làm đồ án tốt nghiệp Flutter',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Môn học / Lĩnh vực',
                      hintText: 'VD: Đồ án CNTT, TOEIC, Thuật toán',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Số thành viên cần tuyển:', style: TextStyle(fontSize: 13)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: needed > 1 ? () => setDialogState(() => needed--) : null,
                      ),
                      Text('$needed', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setDialogState(() => needed++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả chi tiết mục tiêu & yêu cầu',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) return;

                  final prefs = await SharedPreferences.getInstance();
                  final myEmail = prefs.getString('user_email') ?? '0000@gmail.com';
                  final myName = myEmail.split('@').first;

                  try {
                    await http.post(
                      Uri.parse(ApiConfig.posts),
                      headers: {'Content-Type': 'application/json; charset=utf-8'},
                      body: jsonEncode({
                        'authorName': myName,
                        'authorEmail': myEmail,
                        'authorAvatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
                        'university': 'ICTU',
                        'title': titleController.text.trim(),
                        'description': descController.text.trim().isNotEmpty
                            ? descController.text.trim()
                            : 'Cần tìm bạn sinh viên cùng chí hướng học tập và trao đổi tài liệu.',
                        'subject': subjectController.text.trim(),
                        'tags': [subjectController.text.trim(), 'ICTU', 'Học nhóm'],
                        'membersCurrent': 1,
                        'membersNeeded': needed,
                      }),
                    );
                    await _fetchPosts();
                  } catch (e) {
                    debugPrint('Lỗi đăng bài học tập: $e');
                  }

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã đăng bài thành công lên hệ thống! 🎉'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                child: const Text('Đăng Tin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
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
              icon: const Icon(Icons.add_rounded),
              label: Text(
                _activeTab == 0 ? 'Tạo Nhóm Học Mới' : 'Chia Sẻ Tài Liệu',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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

                // 3. SEGMENTED TABS
                _buildSegmentedTab(),

                // 4. LỌC CHỦ ĐỀ
                _buildCategoryFilters(),

                const SizedBox(height: 6),

                // 5. NỘI DUNG CHÍNH
                Expanded(
                  child: _activeTab == 0
                      ? (_isLoadingPosts
                          ? const Center(child: CircularProgressIndicator())
                          : _buildStudyGroupsList())
                      : _buildMaterialsList(),
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
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Góc Học Tập & Đồ Án Sinh Viên',
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
                      'Bài đăng thực tế từ sinh viên • Trao đổi trực tiếp',
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
            onPressed: _fetchPosts,
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
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: _activeTab == 0
                ? 'Tìm nhóm Đồ án, TOEIC, Flutter, Thuật toán...'
                : 'Tìm đề thi, giáo trình, slide bài giảng...',
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
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
                onTap: () => setState(() => _activeTab = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _activeTab == 0 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _activeTab == 0 ? AppColors.cardShadow : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.groups_rounded,
                        size: 18,
                        color: _activeTab == 0 ? AppColors.primary : AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bài Đăng Nhóm (${_posts.length})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _activeTab == 0 ? AppColors.primary : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeTab = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _activeTab == 1 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _activeTab == 1 ? AppColors.cardShadow : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 18,
                        color: _activeTab == 1 ? AppColors.primary : AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Kho Tài Liệu (${_materials.length})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _activeTab == 1 ? AppColors.primary : AppColors.textMuted,
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

  Widget _buildCategoryFilters() {
    final categories = _activeTab == 0
        ? ['Tất cả', 'Đồ án', 'Ngoại ngữ', 'Lập trình', 'ICTU']
        : ['Tất cả', 'CNTT & Lập trình', 'Cơ sở dữ liệu', 'Tiếng Anh'];

    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;

          return ChoiceChip(
            label: Text(
              cat,
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
                _selectedCategory = cat;
              });
            },
          );
        },
      ),
    );
  }

  // 1. DANH SÁCH NHÓM HỌC TẬP
  Widget _buildStudyGroupsList() {
    final query = _searchController.text.trim().toLowerCase();

    final filteredPosts = _posts.where((p) {
      final matchesQuery = query.isEmpty ||
          p.title.toLowerCase().contains(query) ||
          p.subject.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query) ||
          p.tags.any((t) => t.toLowerCase().contains(query));

      if (!matchesQuery) return false;

      if (_selectedCategory == 'Tất cả') return true;
      if (_selectedCategory == 'Đồ án') return p.subject.contains('Đồ án');
      if (_selectedCategory == 'Ngoại ngữ') return p.subject.contains('Ngoại ngữ') || p.subject.contains('TOEIC');
      if (_selectedCategory == 'Lập trình') return p.tags.any((t) => t.contains('Flutter') || t.contains('AI') || t.contains('C#') || t.contains('C/C++'));
      if (_selectedCategory == 'ICTU') return p.university.contains('ICTU');
      return true;
    }).toList();

    if (filteredPosts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school_outlined, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chưa có bài đăng tìm bạn học nào từ sinh viên.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Hãy bấm "Tạo Nhóm Học Mới" ở góc dưới để đăng tin tìm bạn cùng làm đồ án / ôn thi ngay!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 1100 ? 3 : (width >= 720 ? 2 : 1);

    if (crossAxisCount == 1) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: filteredPosts.length,
        itemBuilder: (context, index) {
          final post = filteredPosts[index];
          return _buildPostCard(post, isGrid: false);
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
      itemCount: filteredPosts.length,
      itemBuilder: (context, index) {
        final post = filteredPosts[index];
        return _buildPostCard(post, isGrid: true);
      },
    );
  }

  Widget _buildPostCard(StudyPost post, {bool isGrid = false}) {
    final progress = post.membersCurrent / post.membersNeeded;

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
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(post.authorAvatar),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      Text(
                        '${post.authorEmail} • ${_formatTimeAgo(post.createdAt)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (post.authorEmail.toLowerCase() == _userEmail.toLowerCase())
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                    tooltip: 'Xóa bài của tôi',
                    onPressed: () => _deletePost(post),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    post.subject,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.3),
            ),
            const SizedBox(height: 8),
            Text(
              post.description,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: post.tags.map((tag) {
                return GradientPillBadge(
                  label: '#$tag',
                  backgroundColor: AppColors.primarySoft,
                  foregroundColor: AppColors.primary,
                  fontSize: 11,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.group_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Thành viên: ${post.membersCurrent}/${post.membersNeeded} bạn (còn ${post.membersNeeded - post.membersCurrent} chỗ)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: AppColors.buttonShadow,
                  ),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.white),
                    label: const Text('Nhắn Tin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                    final partner = UserProfile(
                      id: post.authorEmail.hashCode.abs() % 10000,
                      email: post.authorEmail,
                      name: post.authorName,
                      university: post.university,
                      major: post.subject,
                      avatarUrl: post.authorAvatar,
                      bio: post.description,
                      rentalBudget: 2000000,
                      roomLocation: 'Gần trường ICTU',
                      roomStatus: 'Đang tìm bạn học',
                      gender: 'Nam',
                      isSmoker: false,
                      hasPet: false,
                      studyGoal: post.title,
                      studySkills: post.tags,
                      lifestyleTags: ['Nghiêm túc', 'Trách nhiệm'],
                      compatibilityScore: 98,
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(partner: partner),
                      ),
                    );
                  },
                ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 2. DANH SÁCH KHO TÀI LIỆU
  Widget _buildMaterialsList() {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = _materials.where((m) {
      final matches = query.isEmpty ||
          m.title.toLowerCase().contains(query) ||
          m.courseName.toLowerCase().contains(query) ||
          m.description.toLowerCase().contains(query);
      return matches;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.folder_open_rounded, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kho tài liệu hiện đang cập nhật.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Bấm nút "Chia Sẻ Tài Liệu" ở góc dưới để đăng đề thi, slide bài giảng môn học!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 1100 ? 3 : (width >= 720 ? 2 : 1);

    if (crossAxisCount == 1) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final mat = filtered[index];
          return _buildMaterialCard(mat, isGrid: false);
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 220,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final mat = filtered[index];
        return _buildMaterialCard(mat, isGrid: true);
      },
    );
  }

  Widget _buildMaterialCard(StudyMaterial mat, {bool isGrid = false}) {
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: mat.fileType == 'PDF' ? AppColors.errorSoft : AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    mat.fileType,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: mat.fileType == 'PDF' ? AppColors.error : AppColors.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  mat.fileSize,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const Spacer(),
                const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                Text(' ${mat.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              mat.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Môn: ${mat.courseName} • Chia sẻ bởi ${mat.authorName}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              mat.description,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Row(
                  children: [
                    const Icon(Icons.download_rounded, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('${mat.downloadCount} lượt tải', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(width: 14),
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded, size: 16, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text('${mat.likesCount}', style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                  label: const Text('Tải Về', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đang tải tài liệu "${mat.title}" (${mat.fileSize})! 📥'),
                        backgroundColor: AppColors.success,
                      ),
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

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inHours < 1) return 'Vừa xong';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }
}
