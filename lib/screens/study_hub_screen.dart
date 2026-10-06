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
    _loadMaterials();
  }

  Future<void> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email != null && email.isNotEmpty) {
      if (mounted) setState(() => _userEmail = email);
    }
  }

  Future<void> _loadMaterials() async {
    final prefs = await SharedPreferences.getInstance();
    final customList = prefs.getStringList('my_study_materials') ?? [];
    final customMaterials = customList.map((str) {
      try {
        return StudyMaterial.fromJson(jsonDecode(str));
      } catch (_) {
        return null;
      }
    }).whereType<StudyMaterial>().toList();

    final samples = StudyMaterial.getSampleMaterials();
    if (mounted) {
      setState(() {
        _materials = [...customMaterials, ...samples];
      });
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
      setState(() {
        _posts.removeWhere((p) => p.id == post.id);
      });

      final prefs = await SharedPreferences.getInstance();
      final customList = prefs.getStringList('my_study_posts') ?? [];
      final updatedList = customList.where((str) {
        try {
          return jsonDecode(str)['id'] != post.id;
        } catch (_) {
          return true;
        }
      }).toList();
      await prefs.setStringList('my_study_posts', updatedList);

      try {
        await http.delete(Uri.parse('${ApiConfig.posts}?id=${post.id}'));
      } catch (e) {
        debugPrint('Lỗi xóa bài đăng từ server: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bài đăng thành công!'), backgroundColor: AppColors.success),
        );
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

    // 1. Tải danh sách bài đăng tùy chỉnh đã lưu trong SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final customList = prefs.getStringList('my_study_posts') ?? [];
    final customPosts = customList.map((str) {
      try {
        return StudyPost.fromJson(jsonDecode(str));
      } catch (_) {
        return null;
      }
    }).whereType<StudyPost>().toList();

    try {
      final res = await http.get(Uri.parse(ApiConfig.posts)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final loaded = data.map((e) => StudyPost.fromJson(e as Map<String, dynamic>)).toList();
        final all = loaded.isNotEmpty ? loaded : StudyPost.getSamplePosts();

        for (final cp in customPosts.reversed) {
          if (!all.any((p) => p.id == cp.id)) {
            all.insert(0, cp);
          }
        }

        if (mounted) {
          setState(() {
            _posts = all;
          });
        }
      } else {
        final all = StudyPost.getSamplePosts();
        for (final cp in customPosts.reversed) {
          if (!all.any((p) => p.id == cp.id)) {
            all.insert(0, cp);
          }
        }
        if (mounted) {
          setState(() {
            _posts = all;
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải bài đăng học tập từ server: $e');
      final all = StudyPost.getSamplePosts();
      for (final cp in customPosts.reversed) {
        if (!all.any((p) => p.id == cp.id)) {
          all.insert(0, cp);
        }
      }
      if (mounted) {
        setState(() {
          _posts = all;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingPosts = false);
    }
  }

  void _showCreatePostDialog() {
    if (_activeTab == 0) {
      _showCreateGroupDialog();
    } else {
      _showCreateMaterialDialog();
    }
  }

  // DIALOG TẠO NHÓM HỌC TẬP MỚI
  void _showCreateGroupDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final subjectController = TextEditingController(text: 'Đồ án tốt nghiệp');
    final universityController = TextEditingController(text: 'ICTU');
    final contactController = TextEditingController(text: '0988 123 456');
    int needed = 3;
    String studyType = 'Online & Offline kết hợp';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Container(
            padding: EdgeInsets.only(
              top: 24,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.group_add_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Tạo Nhóm Học Tập & Đồ Án Mới 🎓',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Đăng tin tuyển thành viên học nhóm đồ án, ôn thi hoặc tự học tại trường.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề nhóm học tập *',
                      hintText: 'VD: Nhóm làm Đồ án Tốt nghiệp Flutter K21',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: subjectController,
                          decoration: const InputDecoration(
                            labelText: 'Môn học / Lĩnh vực',
                            hintText: 'VD: Đồ án CNTT, TOEIC',
                            prefixIcon: Icon(Icons.book_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: universityController,
                          decoration: const InputDecoration(
                            labelText: 'Trường đại học',
                            hintText: 'ICTU, TNUT...',
                            prefixIcon: Icon(Icons.school_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people_outline_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        const Text('Số thành viên cần tuyển:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.textSecondary),
                          onPressed: needed > 1 ? () => setDialogState(() => needed--) : null,
                        ),
                        Text('$needed bạn', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                          onPressed: needed < 10 ? () => setDialogState(() => needed++) : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contactController,
                    decoration: const InputDecoration(
                      labelText: 'Thông tin liên hệ (Zalo / SĐT)',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Mục tiêu nhóm & yêu cầu thành viên',
                      hintText: 'VD: Nhóm họp vào các buổi tối, cần bạn có tinh thần trách nhiệm cao...',
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
                        elevation: 3,
                      ),
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập tiêu đề nhóm học!'), backgroundColor: AppColors.error),
                          );
                          return;
                        }

                        final prefs = await SharedPreferences.getInstance();
                        final myEmail = prefs.getString('user_email') ?? '0000@gmail.com';
                        final myName = myEmail.split('@').first;

                        final newPost = StudyPost(
                          id: 'post_custom_${DateTime.now().millisecondsSinceEpoch}',
                          authorName: myName,
                          authorEmail: myEmail,
                          authorAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
                          university: universityController.text.trim().isNotEmpty ? universityController.text.trim() : 'ICTU',
                          title: titleController.text.trim(),
                          description: descController.text.trim().isNotEmpty
                              ? descController.text.trim()
                              : 'Cần tìm các bạn sinh viên cùng chí hướng học tập, liên hệ: ${contactController.text.trim()}',
                          subject: subjectController.text.trim().isNotEmpty ? subjectController.text.trim() : 'Học tập',
                          tags: [subjectController.text.trim(), universityController.text.trim(), studyType, 'Tuyển TV'],
                          membersCurrent: 1,
                          membersNeeded: needed,
                          createdAt: DateTime.now(),
                          partnerId: 0,
                        );

                        // 1. Thêm vào đầu danh sách state ngay lập tức
                        setState(() {
                          _posts.insert(0, newPost);
                        });

                        // 2. Lưu vào SharedPreferences để không bị mất khi F5
                        final customList = prefs.getStringList('my_study_posts') ?? [];
                        customList.insert(0, jsonEncode(newPost.toJson()));
                        await prefs.setStringList('my_study_posts', customList);

                        // 3. Gửi lên Backend API nếu có mạng
                        try {
                          await http.post(
                            Uri.parse(ApiConfig.posts),
                            headers: {'Content-Type': 'application/json; charset=utf-8'},
                            body: jsonEncode(newPost.toJson()),
                          );
                        } catch (e) {
                          debugPrint('Lỗi gửi bài đăng lên server: $e');
                        }

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🎉 Đã tạo nhóm học tập mới thành công! Nhóm của bạn đang hiển thị ở đầu danh sách.'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text('Tạo Nhóm Ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // DIALOG CHIA SẺ TÀI LIỆU HỌC TẬP MỚI
  void _showCreateMaterialDialog() {
    final titleController = TextEditingController();
    final subjectController = TextEditingController(text: 'Công nghệ thông tin');
    final descController = TextEditingController();
    String fileType = 'PDF';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Container(
            padding: EdgeInsets.only(
              top: 24,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.upload_file_rounded, color: AppColors.secondary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Chia Sẻ Tài Liệu & Đề Thi 📚',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Chia sẻ giáo trình, đề thi các kỳ hoặc bài tập lớn cho cộng đồng sinh viên.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tên tài liệu / giáo trình *',
                      hintText: 'VD: Tổng hợp Đề thi & Đáp án Cấu trúc dữ liệu',
                      prefixIcon: Icon(Icons.menu_book_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Môn học / Chuyên ngành',
                      hintText: 'VD: Cơ sở dữ liệu, Tiếng Anh...',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: ['PDF', 'ZIP', 'DOCX', 'SLIDE'].map((type) {
                      final isSel = fileType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(type, style: TextStyle(color: isSel ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          onSelected: (_) => setDialogState(() => fileType = type),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả tóm tắt tài liệu / Link Google Drive',
                      hintText: 'VD: Tài liệu bao gồm 5 đề thi các năm 2022-2024 có đáp án chi tiết...',
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

                        final newMat = StudyMaterial(
                          id: 'mat_custom_${DateTime.now().millisecondsSinceEpoch}',
                          title: titleController.text.trim(),
                          courseName: subjectController.text.trim().isNotEmpty ? subjectController.text.trim() : 'Chung',
                          fileType: fileType,
                          fileSize: '3.5 MB',
                          authorName: myName,
                          university: 'ICTU',
                          downloadCount: 1,
                          likesCount: 1,
                          rating: 5.0,
                          description: descController.text.trim(),
                          uploadDate: DateTime.now(),
                        );

                        setState(() {
                          _materials.insert(0, newMat);
                        });

                        final customList = prefs.getStringList('my_study_materials') ?? [];
                        customList.insert(0, jsonEncode(newMat.toJson()));
                        await prefs.setStringList('my_study_materials', customList);

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🎉 Đã chia sẻ tài liệu thành công lên kho học tập!'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text('Chia Sẻ Ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: Icon(_activeTab == 0 ? Icons.group_add_rounded : Icons.upload_file_rounded),
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
                _buildHeader(isDesktop),

                // 2. Ô TÌM KIẾM
                _buildSearchBar(isDesktop),

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

  Widget _buildHeader(bool isDesktop) {
    return Container(
      padding: EdgeInsets.fromLTRB(18, isDesktop ? 16 : 14, 18, isDesktop ? 14 : 10),
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
          if (isDesktop) ...[
            ElevatedButton.icon(
              onPressed: _showCreatePostDialog,
              icon: Icon(_activeTab == 0 ? Icons.group_add_rounded : Icons.upload_file_rounded, size: 18),
              label: Text(
                _activeTab == 0 ? 'Tạo Nhóm Học Mới' : 'Chia Sẻ Tài Liệu',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Làm mới',
            onPressed: () {
              _fetchPosts();
              _loadMaterials();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDesktop) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
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
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _showCreatePostDialog,
            icon: Icon(
              _activeTab == 0 ? Icons.group_add_rounded : Icons.upload_file_rounded,
              size: 18,
            ),
            label: Text(
              _activeTab == 0 ? 'Tạo Nhóm Mới' : 'Chia Sẻ',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 18 : 12, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
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
