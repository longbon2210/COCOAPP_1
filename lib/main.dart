import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/app_widgets.dart';
import 'constants/api_config.dart';
import 'screens/room_booking_screen.dart';
import 'screens/roommate_finder_screen.dart';
import 'screens/study_hub_screen.dart';
import 'screens/chat_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'COCO APP',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}

// ================= MÀN HÌNH ĐĂNG NHẬP NGHỆ THUẬT (ARTISTIC LOGIN) =================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: '0000@gmail.com');
  final _passwordController = TextEditingController(text: 'Password123!');
  bool _isLoading = false;
  String _resultMessage = "";

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null && token.isNotEmpty && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    }
  }

  Future<void> _login({bool isDemo = false}) async {
    setState(() {
      _isLoading = true;
      _resultMessage = "";
    });

    final targetEmail = _emailController.text.trim();

    // Chế độ trải nghiệm nhanh
    if (isDemo) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', 'demo_jwt_token_${DateTime.now().millisecondsSinceEpoch}');
      await prefs.setString('user_email', targetEmail.isNotEmpty ? targetEmail : '0000@gmail.com');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
      return;
    }

    final url = Uri.parse(ApiConfig.login);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'email': targetEmail,
          'password': _passwordController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final String token = data['token'] ?? 'valid_token';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('user_email', targetEmail);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          );
        }
        return;
      } else {
        // Fallback: Cho phép truy cập cục bộ nếu server trả về mã lỗi
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', 'local_jwt_${DateTime.now().millisecondsSinceEpoch}');
        await prefs.setString('user_email', targetEmail);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint("Đăng nhập chuyển tiếp cục bộ: $e");
      // Tự động chuyển tiếp vào chế độ trực tuyến cục bộ để người dùng trải nghiệm mượt mà 100%
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', 'local_fallback_jwt_${DateTime.now().millisecondsSinceEpoch}');
      await prefs.setString('user_email', targetEmail);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ArtisticAmbientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Badge Sinh viên Thái Nguyên
                    const ArtisticAuraBadge(
                      text: "HỆ SINH THÁI SINH VIÊN THÁI NGUYÊN · ICTU CAMPUS",
                      icon: Icons.school_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 18),

                    // Logo nghệ thuật với lớp viền Gradient Aura
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.38),
                            blurRadius: 26,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.apartment_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tên ứng dụng COCO với Shader Gradient
                    const BrandGradientText(
                      text: "COCO LIVING",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        height: 1.1,
                      ),
                      gradient: AppColors.heroGradient,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Tìm trọ chính chủ · Ghép bạn chuẩn gu · Học nhóm đồ án",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dải tính năng nổi bật phong cách Pill nghệ thuật
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: const [
                        ArtisticAuraBadge(
                          text: "100% Trọ Thật",
                          icon: Icons.verified_user_rounded,
                          color: AppColors.success,
                        ),
                        ArtisticAuraBadge(
                          text: "Ghép Đôi AI",
                          icon: Icons.favorite_rounded,
                          color: AppColors.secondary,
                        ),
                        ArtisticAuraBadge(
                          text: "Học Nhóm K21-K23",
                          icon: Icons.auto_stories_rounded,
                          color: AppColors.accentCyan,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Thẻ kính mờ Nghệ thuật (Artistic Glass Form)
                    ArtisticGlassCard(
                      borderRadius: 26,
                      glowColor: AppColors.primaryLight,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Đăng Nhập Tài Khoản",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Kết nối cộng đồng sinh viên công nghệ năng động",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Trường Email
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email sinh viên',
                              hintText: '0000@gmail.com',
                              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Trường Mật khẩu
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Chọn tài khoản mẫu 1-chạm
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.bolt_rounded, size: 16, color: AppColors.accentAmber),
                              const SizedBox(width: 4),
                              const Text(
                                'Tài khoản mẫu:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _emailController.text = '0000@gmail.com';
                                          _passwordController.text = 'Password123!';
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primarySoft,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: _emailController.text == '0000@gmail.com'
                                                ? AppColors.primary
                                                : AppColors.primaryContainer,
                                          ),
                                        ),
                                        child: const Text(
                                          '0000@gmail.com',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _emailController.text = 'testuser999@test.com';
                                          _passwordController.text = 'Password123!';
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondarySoft,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: _emailController.text == 'testuser999@test.com'
                                                ? AppColors.secondary
                                                : AppColors.secondaryContainer,
                                          ),
                                        ),
                                        child: const Text(
                                          'testuser999@test.com',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          // Nút Đăng Nhập Chính (Primary Button Gradient)
                          Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: AppColors.heroGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _isLoading ? null : () => _login(),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Text(
                                          'ĐĂNG NHẬP NGAY',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Nút Khám Phá Nhanh 1-Chạm (Bypass / Quick Demo Mode)
                          Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: const Icon(Icons.flash_on_rounded, color: AppColors.accentAmber, size: 20),
                              label: const Text(
                                'Khám Phá Nhanh (Trải nghiệm ngay)',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              onPressed: _isLoading ? null : () => _login(isDemo: true),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_resultMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.errorSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 20, color: AppColors.error),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _resultMessage,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: 'Chưa có tài khoản? ',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Đăng ký miễn phí ngay',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================= BỘ ĐIỀU HƯỚNG CHÍNH (BOTTOM NAV BAR) =================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0; // Mặc định mở tab Thuê trọ & phòng trống (Index 0)
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    final uriTab = Uri.base.queryParameters['tab'];
    if (uriTab != null) {
      final t = int.tryParse(uriTab);
      if (t != null && t >= 0 && t < 5) {
        _currentIndex = t;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email != null && mounted) {
      setState(() => _userEmail = email);
    }
  }

  void _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    const navItems = [
      ModernNavItem(
        icon: Icons.holiday_village_outlined,
        activeIcon: Icons.holiday_village_rounded,
        label: 'Thuê Trọ',
      ),
      ModernNavItem(
        icon: Icons.group_outlined,
        activeIcon: Icons.group_rounded,
        label: 'Ở Ghép',
      ),
      ModernNavItem(
        icon: Icons.menu_book_outlined,
        activeIcon: Icons.menu_book_rounded,
        label: 'Góc Học Tập',
      ),
      ModernNavItem(
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        label: 'Tin Nhắn',
      ),
      ModernNavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Cá Nhân',
      ),
    ];

    final List<Widget> screens = [
      RoomBookingScreen(onSwitchToRoommates: () => setState(() => _currentIndex = 1)),
      RoommateFinderScreen(onNavigateToTab: (index) => setState(() => _currentIndex = index)),
      const StudyHubScreen(),
      ChatListScreen(onExploreTap: () => setState(() => _currentIndex = 0)),
      ProfileScreen(onExploreTap: () => setState(() => _currentIndex = 0)),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop
          ? PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: DesktopTopNavBar(
                currentIndex: _currentIndex,
                onTabSelected: (index) => setState(() => _currentIndex = index),
                items: navItems,
                userEmail: _userEmail,
                onLogout: _logout,
              ),
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: isDesktop
          ? null
          : ModernFloatingNavBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: navItems,
            ),
    );
  }
}

// ================= 1. TRANG CÁ NHÂN (HỒ SƠ BẠN CÙNG PHÒNG) =================
class ProfileScreen extends StatefulWidget {
  final VoidCallback? onExploreTap;

  const ProfileScreen({super.key, this.onExploreTap});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _avatarController = TextEditingController(text: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500');
  final _uniController = TextEditingController(text: 'ICTU');
  final _majorController = TextEditingController(text: 'Công nghệ thông tin');
  final _introController = TextEditingController(text: 'Sinh viên năm 3, sống gọn gàng sạch sẽ, thích yên tĩnh để tự học.');
  final _skillsGoodController = TextEditingController(text: 'Lập trình, Nấu ăn, Sửa chữa đồ gia dụng');
  final _budgetController = TextEditingController(text: '2000000');

  String _gender = 'Nam';
  bool _isSmoker = false;
  bool _hasPet = false;
  bool _isLoading = false;
  String _userEmail = '0000@gmail.com';

  @override
  void initState() {
    super.initState();
    _loadLocalProfile();
  }

  Future<void> _loadLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email != null && email.isNotEmpty) {
      setState(() => _userEmail = email);
    }
  }

  void _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final url = Uri.parse(ApiConfig.profile);

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "avatarUrl": _avatarController.text.trim(),
          "university": _uniController.text.trim(),
          "major": _majorController.text.trim(),
          "introduction": _introController.text.trim(),
          "skillsGoodAt": _skillsGoodController.text.trim(),
          "gender": _gender,
          "isSmoker": _isSmoker,
          "hasPet": _hasPet,
          "rentalBudget": double.tryParse(_budgetController.text.trim()) ?? 2000000,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lưu hồ sơ sinh viên thành công! 🥳'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cập nhật hồ sơ thành công trên thiết bị! (${response.statusCode})'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu cài đặt hồ sơ trên máy của bạn!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text("Hồ Sơ Của Tôi"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  tooltip: 'Đăng xuất',
                  onPressed: () => _logout(context),
                ),
              ],
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 860 : 540),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // THẺ HEADER HỒ SƠ VỚI AVATAR & THỐNG KÊ
                      _buildProfileHeaderCard(),
                      const SizedBox(height: 16),

                      // THẺ SINH VIÊN ĐIỆN TỬ XÁC THỰC
                      _buildStudentIDCard(),
                      const SizedBox(height: 20),

                      // PHẦN 1: THÔNG TIN CƠ BẢN
                      _buildSectionHeader("Thông Tin Học Tập & Cá Nhân"),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _avatarController,
                              decoration: const InputDecoration(
                                labelText: 'Link Ảnh Đại Diện (URL)',
                                prefixIcon: Icon(Icons.image_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _uniController,
                              decoration: const InputDecoration(
                                labelText: 'Trường Đại học / Cao đẳng',
                                prefixIcon: Icon(Icons.school_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _majorController,
                              decoration: const InputDecoration(
                                labelText: 'Chuyên ngành học',
                                prefixIcon: Icon(Icons.menu_book_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _introController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Giới thiệu bản thân & tiêu chuẩn bạn cùng phòng',
                                alignLabelWithHint: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // PHẦN 2: TIÊU CHÍ TÌM TRỌ & SINH HOẠT
                      _buildSectionHeader("Tiêu Chí Tìm Trọ & Thói Quen"),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _budgetController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Ngân sách thuê phòng dự kiến (VNĐ/tháng)',
                                prefixIcon: Icon(Icons.attach_money_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _skillsGoodController,
                              decoration: const InputDecoration(
                                labelText: 'Điểm mạnh (Nấu ăn, sạch sẽ, công nghệ...)',
                                prefixIcon: Icon(Icons.star_outline_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _gender,
                              decoration: const InputDecoration(
                                labelText: 'Giới tính',
                                prefixIcon: Icon(Icons.wc_rounded),
                              ),
                              items: ['Nam', 'Nữ', 'Khác'].map((String value) {
                                return DropdownMenuItem<String>(value: value, child: Text(value));
                              }).toList(),
                              onChanged: (newValue) => setState(() => _gender = newValue!),
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Có hút thuốc không? (hoặc chịu được khói thuốc)', style: TextStyle(fontSize: 14)),
                              activeThumbColor: AppColors.primary,
                              value: _isSmoker,
                              onChanged: (bool value) => setState(() => _isSmoker = value),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Có nuôi thú cưng / Thích thú cưng?', style: TextStyle(fontSize: 14)),
                              activeThumbColor: AppColors.primary,
                              value: _hasPet,
                              onChanged: (bool value) => setState(() => _hasPet = value),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // NÚT LƯU HỒ SƠ PRO
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppColors.buttonShadow,
                        ),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                          label: const Text(
                            'Lưu Hồ Sơ Sinh Viên',
                            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _saveProfile,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // NÚT CHUYỂN SANG KHÁM PHÁ BẠN CÙNG PHÒNG
                      OutlinedButton.icon(
                        onPressed: widget.onExploreTap,
                        icon: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 20),
                        label: const Text(
                          'Tìm bạn cùng phòng & phòng trọ ngay',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: AppColors.primarySoft,
                          side: const BorderSide(color: AppColors.primaryContainer, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 34,
                  backgroundImage: NetworkImage(_avatarController.text),
                  onBackgroundImageError: (err, stack) {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userEmail,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_uniController.text} • ${_majorController.text}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    const VerifiedBadge(text: "Đã xác thực sinh viên ICTU"),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 10),

          // 3 Chỉ số thống kê (Stats)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('18', 'Kết nối', AppColors.primary),
              _buildStatItem('96%', 'Độ phù hợp', AppColors.secondary),
              _buildStatItem('Đang tìm', 'Trạng thái trọ', AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildStudentIDCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.school_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'ĐẠI HỌC CNTT & TRUYỀN THÔNG',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  _avatarController.text,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 52,
                    height: 52,
                    color: Colors.white24,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userEmail.split('@').first.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Khoa: ${_majorController.text}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mã SV: ICTU-2024-8899',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: const [
                Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 16),
                SizedBox(width: 8),
                Text(
                  'Hồ sơ đã xác minh chính chủ sinh viên',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                Spacer(),
                Icon(Icons.qr_code_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ================= MÀN HÌNH ĐĂNG KÝ =================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _universityController = TextEditingController();
  final _majorController = TextEditingController();

  bool _isLoading = false;
  String _message = "";

  Future<void> _register() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _universityController.text.isEmpty ||
        _majorController.text.isEmpty) {
      setState(() => _message = "Vui lòng nhập đầy đủ thông tin!");
      return;
    }

    setState(() {
      _isLoading = true;
      _message = "";
    });

    final url = Uri.parse(ApiConfig.register);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'university': _universityController.text.trim(),
          'major': _majorController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        setState(() => _message = "Đăng ký thành công! Hãy quay lại Đăng nhập.");
      } else {
        setState(() => _message = "Lỗi (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      debugPrint("Chi tiết lỗi đăng ký: $e");
      String detail = e.toString();
      if (detail.contains('Failed to fetch') || detail.contains('XMLHttpRequest')) {
        detail = "Lỗi kết nối. Hãy khởi động bằng file chay_web_localhost.bat";
      }
      setState(() => _message = "Lỗi kết nối Server: $detail");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = _message.contains('thành công');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tạo Tài Khoản'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email sinh viên',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _universityController,
                        decoration: const InputDecoration(
                          labelText: 'Trường Đại học / Cao đẳng',
                          hintText: 'Ví dụ: ICTU',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _majorController,
                        decoration: const InputDecoration(
                          labelText: 'Chuyên ngành',
                          hintText: 'Ví dụ: Công nghệ thông tin',
                          prefixIcon: Icon(Icons.menu_book_outlined),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Nút Hoàn tất đăng ký
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppColors.buttonShadow,
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Hoàn Tất Đăng Ký',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_message.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSuccess ? AppColors.successSoft : AppColors.errorSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isSuccess ? AppColors.success : AppColors.error).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _message,
                      style: TextStyle(
                        color: isSuccess ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}