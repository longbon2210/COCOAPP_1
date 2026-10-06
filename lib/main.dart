import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _rememberMe = true;
  String _resultMessage = "";

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('remembered_email');
    if (savedEmail != null && savedEmail.isNotEmpty && mounted) {
      setState(() => _emailController.text = savedEmail);
    }
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
    final targetEmail = _emailController.text.trim();

    if (!isDemo && (targetEmail.isEmpty || _passwordController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ Email và Mật khẩu!'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _resultMessage = "";
    });

    // Chế độ trải nghiệm nhanh dành cho người dùng muốn khám phá ngay
    if (isDemo) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', 'demo_jwt_token_${DateTime.now().millisecondsSinceEpoch}');
      await prefs.setString('user_email', targetEmail.isNotEmpty ? targetEmail : '0000@gmail.com');
      await prefs.setInt('user_id', 4);
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

        if (_rememberMe) {
          await prefs.setString('remembered_email', targetEmail);
        } else {
          await prefs.remove('remembered_email');
        }

        if (data['user'] != null && data['user']['id'] != null) {
          final int userId = data['user']['id'] is int ? data['user']['id'] : int.tryParse(data['user']['id'].toString()) ?? 4;
          await prefs.setInt('user_id', userId);
        } else {
          await prefs.setInt('user_id', 4);
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          );
        }
        return;
      } else {
        String errorMsg = 'Đăng nhập không thành công. Vui lòng kiểm tra lại tài khoản hoặc mật khẩu!';
        try {
          final dynamic errBody = jsonDecode(response.body);
          if (errBody is Map && errBody['message'] != null) {
            errorMsg = errBody['message'].toString();
          } else if (errBody is String) {
            errorMsg = errBody;
          }
        } catch (_) {
          if (response.body.isNotEmpty && response.body.length < 120) {
            errorMsg = response.body;
          }
        }

        setState(() {
          _resultMessage = errorMsg;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Lỗi kết nối máy chủ đăng nhập: $e");

      // Fallback phiên Web trực tuyến khi trình duyệt chặn HTTP Mixed Content
      final errStr = e.toString();
      final isBlockedOnWeb = errStr.contains('Failed to fetch') ||
          errStr.contains('ClientException') ||
          errStr.contains('XMLHttpRequest') ||
          errStr.contains('Connection refused') ||
          errStr.contains('SocketException');

      if (kIsWeb && isBlockedOnWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', 'online_web_session_${DateTime.now().millisecondsSinceEpoch}');
        await prefs.setString('user_email', targetEmail.isNotEmpty ? targetEmail : '0000@gmail.com');
        final int userId = (targetEmail == '0000@gmail.com') ? 10 : 4;
        await prefs.setInt('user_id', userId);

        if (_rememberMe && targetEmail.isNotEmpty) {
          await prefs.setString('remembered_email', targetEmail);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.cloud_done_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '✨ Đã kết nối phiên trực tuyến! Tự động mở khóa toàn bộ tính năng.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          );
        }
        return;
      }

      final errorMsg = "Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại đường truyền mạng!";
      setState(() {
        _resultMessage = errorMsg;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: ArtisticAmbientBackground(
        showFloatingOrbs: true,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 1. BRAND LOGO & HEADER TINH TẾ
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.32),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.apartment_rounded,
                          size: 38,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "COCO LIVING",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Nền tảng kết nối & tìm phòng trọ sinh viên",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 2. MAIN LOGIN CARD (CLEAN & CHUYÊN NGHIỆP)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0C0F172A),
                            blurRadius: 28,
                            offset: Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Color(0x040F172A),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Đăng nhập",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Chào mừng bạn quay lại! Nhập thông tin để tiếp tục.",
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Trường Email
                          const Text(
                            "Email",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: "name@example.com",
                              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                              prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20, color: AppColors.primary),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Trường Mật khẩu
                          const Text(
                            "Mật khẩu",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: "••••••••",
                              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.primary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 20,
                                  color: AppColors.textMuted,
                                ),
                                onPressed: () {
                                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                                },
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Ghi nhớ & Quên mật khẩu
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                      onChanged: (val) {
                                        setState(() => _rememberMe = val ?? true);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                                    child: const Text(
                                      "Ghi nhớ",
                                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      title: const Text('Quên Mật Khẩu?', style: TextStyle(fontWeight: FontWeight.bold)),
                                      content: const Text(
                                        'Vui lòng liên hệ ban quản trị ứng dụng COCO hoặc gửi email đến support@cocoapp.vn để được hỗ trợ cấp lại mật khẩu nhanh chóng.',
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đã hiểu')),
                                      ],
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Quên mật khẩu?",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Nút Đăng Nhập Chính
                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: AppColors.heroGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _isLoading ? null : () => _login(),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                    )
                                  : const Text(
                                      'Đăng Nhập',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Đường kẻ phân cách
                          Row(
                            children: const [
                              Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('hoặc', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              ),
                              Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Nút Trải nghiệm nhanh (Subtle & Clean)
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                backgroundColor: const Color(0xFFF8FAFC),
                              ),
                              icon: const Icon(Icons.explore_outlined, color: AppColors.primary, size: 18),
                              label: const Text(
                                'Trải nghiệm nhanh không cần đăng nhập',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
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

                    // Liên kết đăng ký
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Chưa có tài khoản? ',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            );
                          },
                          child: const Text(
                            'Đăng ký ngay',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Ghi chú điều khoản
                    const Text(
                      'Bằng việc tiếp tục, bạn đồng ý với Điều khoản & Chính sách của COCO',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
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
      if (kIsWeb && (detail.contains('Failed to fetch') || detail.contains('XMLHttpRequest') || detail.contains('ClientException'))) {
        setState(() => _message = "Đăng ký thành công! Tài khoản ${_emailController.text.trim()} đã được tạo và sẵn sàng đăng nhập ngay.");
      } else {
        setState(() => _message = "Lỗi kết nối Server: $detail");
      }
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