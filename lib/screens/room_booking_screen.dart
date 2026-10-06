import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_config.dart';
import '../models/room_booking.dart';
import '../models/room_listing.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_widgets.dart';
import 'chat_detail_screen.dart';

class RoomBookingScreen extends StatefulWidget {
  final VoidCallback? onSwitchToRoommates;

  const RoomBookingScreen({super.key, this.onSwitchToRoommates});

  @override
  State<RoomBookingScreen> createState() => _RoomBookingScreenState();
}

class _RoomBookingScreenState extends State<RoomBookingScreen> {
  List<RoomListing> _rooms = [];
  List<RoomBooking> _myBookings = [];
  bool _isLoading = true;
  String _userEmail = '0000@gmail.com';
  String _userName = 'Sinh viên';

  // Bộ lọc tìm kiếm kiểu Booking khách sạn
  String _searchKeyword = '';
  String _selectedLocation = 'Tất cả';
  String _selectedRoomType = 'Tất cả';
  String _selectedPriceRange = 'Tất cả';
  bool _onlyVacant = false;

  final List<String> _locations = [
    'Tất cả',
    'Đường Z115',
    'Cổng ICTU',
    'Tân Thịnh',
    'Quang Trung',
    'Quyết Thắng',
  ];

  final List<String> _roomTypes = [
    'Tất cả',
    'Studio ban công',
    'Gác lửng',
    'Khép kín',
    'Căn hộ mini',
  ];

  final List<String> _priceRanges = [
    'Tất cả',
    'Dưới 1.5 triệu',
    '1.5 - 2.5 triệu',
    'Trên 2.5 triệu',
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserSession();
    _fetchRooms();
    _fetchMyBookings();
  }

  Future<void> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email != null && email.isNotEmpty) {
      if (mounted) {
        setState(() {
          _userEmail = email;
          _userName = email.split('@').first;
        });
      }
    }
  }

  Future<void> _fetchRooms() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(ApiConfig.rooms)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        final loaded = list.map((json) => RoomListing.fromJson(json)).toList();
        if (mounted) {
          setState(() {
            _rooms = loaded.isNotEmpty ? loaded : RoomListing.getSampleRooms();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            if (_rooms.isEmpty) _rooms = RoomListing.getSampleRooms();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Lỗi tải danh sách phòng: $e");
      if (mounted) {
        setState(() {
          if (_rooms.isEmpty) _rooms = RoomListing.getSampleRooms();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMyBookings() async {
    try {
      final url = Uri.parse('${ApiConfig.bookings}?userEmail=$_userEmail');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        final loaded = list.map((json) => RoomBooking.fromJson(json)).toList();
        if (mounted) {
          setState(() {
            _myBookings = loaded;
          });
        }
      }
    } catch (e) {
      debugPrint("Lỗi tải lịch hẹn của tôi: $e");
    }
  }

  Future<void> _deleteRoom(RoomListing room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Xóa Tin Đăng Phòng Trọ?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn xóa tin đăng "${room.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final resp = await http.delete(Uri.parse('${ApiConfig.rooms}?id=${room.id}'));
        if (resp.statusCode == 200) {
          _fetchRooms();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã xóa tin đăng phòng trọ thành công!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint("Lỗi xóa phòng: $e");
      }
    }
  }

  List<RoomListing> get _filteredRooms {
    return _rooms.where((room) {
      // 1. Lọc theo từ khóa tìm kiếm
      if (_searchKeyword.isNotEmpty) {
        final q = _searchKeyword.toLowerCase();
        final match = room.title.toLowerCase().contains(q) ||
            room.address.toLowerCase().contains(q) ||
            room.description.toLowerCase().contains(q) ||
            room.roomType.toLowerCase().contains(q);
        if (!match) return false;
      }

      // 2. Lọc chỉ phòng còn trống (nếu bật)
      if (_onlyVacant && room.vacantRooms <= 0) {
        return false;
      }

      // 3. Lọc khu vực
      if (_selectedLocation != 'Tất cả') {
        if (!room.address.toLowerCase().contains(_selectedLocation.toLowerCase()) &&
            !room.distance.toLowerCase().contains(_selectedLocation.toLowerCase())) {
          return false;
        }
      }

      // 4. Lọc loại phòng
      if (_selectedRoomType != 'Tất cả') {
        if (!room.roomType.toLowerCase().contains(_selectedRoomType.toLowerCase())) {
          return false;
        }
      }

      // 5. Lọc mức giá
      if (_selectedPriceRange == 'Dưới 1.5 triệu' && room.pricePerMonth >= 1500000) {
        return false;
      } else if (_selectedPriceRange == '1.5 - 2.5 triệu' &&
          (room.pricePerMonth < 1500000 || room.pricePerMonth > 2500000)) {
        return false;
      } else if (_selectedPriceRange == 'Trên 2.5 triệu' && room.pricePerMonth <= 2500000) {
        return false;
      }

      return true;
    }).toList();
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      final trieu = price / 1000000;
      return '${trieu.toStringAsFixed(trieu.truncateToDouble() == trieu ? 0 : 1)} triệu/tháng';
    }
    return '${price.toStringAsFixed(0)} đ/tháng';
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';
  }

  // Widget hiển thị ảnh phòng linh hoạt: Hỗ trợ cả Base64 Data URL (ảnh up từ máy) lẫn URL trực tuyến
  Widget _buildRoomImage(String url, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
    if (url.startsWith('data:image')) {
      try {
        final commaIdx = url.indexOf(',');
        final base64Str = commaIdx != -1 ? url.substring(commaIdx + 1) : url;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, _, _) => _fallbackPlaceholder(width, height),
        );
      } catch (_) {
        return _fallbackPlaceholder(width, height);
      }
    } else {
      return Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => _fallbackPlaceholder(width, height),
      );
    }
  }

  Widget _fallbackPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.apartment_rounded, color: AppColors.textMuted, size: 36),
      ),
    );
  }

  // Mở màn hình chat trực tiếp với chủ trọ
  void _openChatWithLandlord(RoomListing room) {
    final landlordProfile = UserProfile(
      id: room.landlordPhone.hashCode.abs(),
      email: room.authorEmail,
      name: room.landlordName,
      university: 'Chủ phòng trọ',
      major: room.address,
      avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500',
      bio: 'Chủ trọ phòng: ${room.title}.',
      rentalBudget: room.pricePerMonth,
      roomLocation: room.address,
      roomStatus: 'Đang cho thuê',
      gender: 'Tất cả',
      isSmoker: false,
      hasPet: false,
      studyGoal: '',
      studySkills: [],
      lifestyleTags: ['Chủ nhà uy tín', 'Hỗ trợ 24/7'],
      compatibilityScore: 99,
      isOnline: true,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(partner: landlordProfile),
      ),
    );
  }

  // Gọi điện thoại cho chủ trọ
  void _showCallLandlordDialog(RoomListing room) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.phone_in_talk_rounded, color: AppColors.success),
            ),
            const SizedBox(width: 12),
            const Text('Liên Hệ Chủ Trọ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chủ nhà: ${room.landlordName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Text('Phòng: ${room.title}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    room.landlordPhone,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
                    tooltip: 'Sao chép SĐT',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: room.landlordPhone));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép số điện thoại chủ trọ!'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text('Nhắn tin trong App'),
            onPressed: () {
              Navigator.pop(ctx);
              _openChatWithLandlord(room);
            },
          ),
        ],
      ),
    );
  }

  // Mở Modal đặt lịch xem phòng trọ (Hotel Booking Style)
  void _openBookingDialog(RoomListing room) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedTimeSlot = '17:00 - 18:00 (Chiều)';
    final phoneController = TextEditingController(text: '0988 123 456');
    final nameController = TextEditingController(text: _userName);
    final noteController = TextEditingController(text: 'Em muốn qua xem phòng ${room.floor} ạ.');
    bool isSubmitting = false;

    final timeSlots = [
      '08:30 - 09:30 (Sáng)',
      '11:30 - 12:30 (Trưa)',
      '17:00 - 18:00 (Chiều)',
      '19:30 - 20:30 (Tối)',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.event_available_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Đặt Lịch Xem Phòng Trực Tiếp',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              'Xác nhận nhanh • Hoàn toàn miễn phí',
                              style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 72,
                            height: 72,
                            child: room.images.isNotEmpty
                                ? _buildRoomImage(room.images.first, width: 72, height: 72)
                                : _fallbackPlaceholder(72, 72),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                room.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    _formatPrice(room.pricePerMonth),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.green.shade300),
                                    ),
                                    child: Text(
                                      'Còn ${room.vacantRooms} phòng trống',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('1. Chọn ngày muốn qua xem:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogCtx,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Ngày ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const Spacer(),
                          const Text('Đổi ngày', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('2. Chọn khung giờ thuận tiện:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: timeSlots.map((slot) {
                      final isSelected = selectedTimeSlot == slot;
                      return ChoiceChip(
                        label: Text(slot),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        backgroundColor: AppColors.background,
                        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                        onSelected: (val) {
                          if (val) setModalState(() => selectedTimeSlot = slot);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('3. Thông tin liên hệ của bạn:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Họ tên',
                            prefixIcon: const Icon(Icons.person_outline, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Số điện thoại',
                            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: 'Ghi chú cho chủ trọ (Tùy chọn)',
                      hintText: 'Ví dụ: Em muốn xem thêm chỗ để xe máy...',
                      prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final phone = phoneController.text.trim();
                              final name = nameController.text.trim();
                              if (phone.isEmpty || name.isEmpty) {
                                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                  const SnackBar(content: Text('Vui lòng nhập họ tên và số điện thoại!')),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              try {
                                final bookingPayload = {
                                  'roomId': room.id,
                                  'roomTitle': room.title,
                                  'roomAddress': room.address,
                                  'landlordName': room.landlordName,
                                  'landlordPhone': room.landlordPhone,
                                  'userEmail': _userEmail,
                                  'userName': name,
                                  'userPhone': phone,
                                  'bookingDate':
                                      '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                                  'timeSlot': selectedTimeSlot,
                                  'note': noteController.text.trim(),
                                  'status': 'Đã xác nhận',
                                };

                                final resp = await http.post(
                                  Uri.parse(ApiConfig.bookings),
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode(bookingPayload),
                                );

                                if (resp.statusCode == 201 || resp.statusCode == 200) {
                                  if (dialogCtx.mounted) {
                                    Navigator.pop(dialogCtx);
                                  }
                                  _fetchMyBookings();
                                  _showBookingSuccessModal(room, selectedDate, selectedTimeSlot);
                                } else {
                                  setModalState(() => isSubmitting = false);
                                  if (dialogCtx.mounted) {
                                    ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                      SnackBar(content: Text('Không thể đặt lịch: ${resp.body}')),
                                    );
                                  }
                                }
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                if (dialogCtx.mounted) {
                                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                    SnackBar(content: Text('Lỗi kết nối đặt lịch: $e')),
                                  );
                                }
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Xác Nhận Đặt Lịch Xem Phòng (Miễn Phí)',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
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

  void _showBookingSuccessModal(RoomListing room, DateTime date, String slot) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Đặt Lịch Xem Phòng Thành Công!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Chủ nhà ${room.landlordName} đã nhận được lịch hẹn vào ngày ${date.day}/${date.month}/${date.year} ($slot).',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('SĐT Chủ nhà:', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      Text(room.landlordPhone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Địa chỉ xem:', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      Expanded(
                        child: Text(
                          room.address,
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showMyBookingsSheet();
            },
            child: const Text('Xem Lịch Hẹn Của Tôi', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text('Nhắn tin cho chủ nhà'),
            onPressed: () {
              Navigator.pop(ctx);
              _openChatWithLandlord(room);
            },
          ),
        ],
      ),
    );
  }

  void _showMyBookingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return Container(
            height: MediaQuery.of(sheetCtx).size.height * 0.8,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                        SizedBox(width: 10),
                        Text(
                          'Lịch Hẹn Xem Phòng Của Tôi',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () async {
                        await _fetchMyBookings();
                        setSheetState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tổng cộng: ${_myBookings.length} lịch hẹn',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const Divider(height: 24),
                Expanded(
                  child: _myBookings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy_rounded, size: 54, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text(
                                'Bạn chưa có lịch hẹn xem phòng nào.',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Khi có phòng ưng ý, bấm "Đặt Lịch Xem Phòng" để lên lịch hẹn!',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _myBookings.length,
                          itemBuilder: (context, idx) {
                            final b = _myBookings[idx];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.green.shade300),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.check_circle_outline_rounded,
                                                size: 14, color: Colors.green),
                                            const SizedBox(width: 4),
                                            Text(
                                              b.status,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                        tooltip: 'Hủy lịch hẹn',
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: sheetCtx,
                                            builder: (c) => AlertDialog(
                                              title: const Text('Hủy Lịch Hẹn?'),
                                              content: Text('Bạn có chắc muốn hủy lịch xem phòng "${b.roomTitle}" không?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(c, false),
                                                  child: const Text('Giữ lại'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(c, true),
                                                  child: const Text('Hủy lịch', style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await http.delete(Uri.parse('${ApiConfig.bookings}?id=${b.id}'));
                                            await _fetchMyBookings();
                                            setSheetState(() {});
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    b.roomTitle,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          b.roomAddress,
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${b.bookingDate} (${b.timeSlot})',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textMuted),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Chủ nhà: ${b.landlordName} • SĐT: ${b.landlordPhone}',
                                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  if (b.note.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Ghi chú: "${b.note}"',
                                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                          side: const BorderSide(color: AppColors.primary),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        icon: const Icon(Icons.copy_rounded, size: 16),
                                        label: const Text('Sao chép SĐT'),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: b.landlordPhone));
                                          ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                            const SnackBar(content: Text('Đã sao chép SĐT chủ trọ!')),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
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

  // Mở Form Đăng Tin Cho Thuê Trọ: Hỗ trợ UP ẢNH TRỰC TIẾP TỪ THIẾT BỊ HOẶC LINK
  void _openAddRoomListingModal() {
    final titleController = TextEditingController();
    final addressController = TextEditingController(text: 'Đường Z115, TP. Thái Nguyên');
    final distanceController = TextEditingController(text: 'Cách cổng ICTU 200m');
    final priceController = TextEditingController();
    final depositController = TextEditingController();
    final vacantRoomsController = TextEditingController(text: '1');
    final totalRoomsController = TextEditingController(text: '6');
    final areaController = TextEditingController(text: '22');
    final landlordPhoneController = TextEditingController();
    final landlordNameController = TextEditingController(text: _userName);
    final descController = TextEditingController();
    final urlInputController = TextEditingController();

    String roomType = 'Phòng khép kín gác lửng';
    final List<String> uploadedImages = [];
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setFormState) {
          return Container(
            height: MediaQuery.of(modalCtx).size.height * 0.92,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              top: 16,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đăng Tin Cho Thuê Trọ Mới',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          Text(
                            'Đầy đủ hình ảnh thực tế giúp tăng 90% lượt liên hệ',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // KHỐI TẢI ẢNH PHÒNG TRỌ (PHOTO UPLOAD SECTION)
                  const Row(
                    children: [
                      Icon(Icons.photo_library_rounded, size: 20, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Hình ảnh phòng trọ *',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tải lên ảnh chụp thực tế từ điện thoại/máy tính hoặc thêm đường link ảnh',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),

                  // Nút bấm chọn ảnh
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.add_photo_alternate_rounded, size: 20),
                          label: const Text('Chọn ảnh từ máy / điện thoại', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            try {
                              final List<XFile> pickedFiles = await _picker.pickMultiImage();
                              if (pickedFiles.isNotEmpty) {
                                for (final file in pickedFiles) {
                                  final bytes = await file.readAsBytes();
                                  final base64String = base64Encode(bytes);
                                  final dataUrl = 'data:image/jpeg;base64,$base64String';
                                  uploadedImages.add(dataUrl);
                                }
                                setFormState(() {});
                              }
                            } catch (e) {
                              debugPrint("Lỗi tải ảnh: $e");
                              if (modalCtx.mounted) {
                                ScaffoldMessenger.of(modalCtx).showSnackBar(
                                  SnackBar(content: Text('Lỗi chọn ảnh: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Thêm link ảnh URL thủ công nếu muốn
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: urlInputController,
                          decoration: InputDecoration(
                            hintText: 'Hoặc dán link ảnh (https://...)',
                            hintStyle: const TextStyle(fontSize: 12),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          final text = urlInputController.text.trim();
                          if (text.isNotEmpty) {
                            uploadedImages.add(text);
                            urlInputController.clear();
                            setFormState(() {});
                          }
                        },
                        child: const Text('Thêm'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Khung xem trước các ảnh đã chọn (Preview Grid)
                  if (uploadedImages.isNotEmpty) ...[
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: uploadedImages.length,
                        itemBuilder: (context, i) {
                          final img = uploadedImages[i];
                          final isCover = i == 0;
                          return Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCover ? AppColors.primary : AppColors.border,
                                width: isCover ? 2 : 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _buildRoomImage(img, width: 110, height: 110),
                                ),
                                if (isCover)
                                  Positioned(
                                    bottom: 4,
                                    left: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Ảnh bìa',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: InkWell(
                                    onTap: () {
                                      uploadedImages.removeAt(i);
                                      setFormState(() {});
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đã chọn ${uploadedImages.length} ảnh (Ảnh đầu tiên sẽ làm ảnh bìa)',
                      style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 36, color: Colors.grey.shade400),
                          const SizedBox(height: 6),
                          const Text(
                            'Chưa có ảnh nào được chọn',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Bấm nút "Chọn ảnh từ máy" ở trên để tải ảnh phòng',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),

                  // CÁC TRƯỜNG THÔNG TIN PHÒNG TRỌ
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Tiêu đề tin đăng *',
                      hintText: 'VD: Phòng khép kín ban công ngõ 18 Z115 gần ICTU...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: 'Địa chỉ cụ thể *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Giá thuê (VNĐ/tháng) *',
                            hintText: '1800000',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: depositController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Tiền cọc (VNĐ)',
                            hintText: '1800000',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: vacantRoomsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Số phòng trống *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: totalRoomsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Tổng số phòng dãy',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: areaController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Diện tích (m²)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: distanceController,
                          decoration: InputDecoration(
                            labelText: 'Khoảng cách trường',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: landlordNameController,
                          decoration: InputDecoration(
                            labelText: 'Tên chủ nhà/người đăng *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: landlordPhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Số điện thoại liên hệ *',
                            hintText: '0988...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Mô tả chi tiết phòng trọ',
                      hintText: 'Giờ giấc, an ninh, đồ đạc có sẵn, nội quy...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // NÚT ĐĂNG TIN
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final title = titleController.text.trim();
                              final addr = addressController.text.trim();
                              final phone = landlordPhoneController.text.trim();
                              final price = double.tryParse(priceController.text.trim());
                              final vacant = int.tryParse(vacantRoomsController.text.trim()) ?? 1;

                              if (title.isEmpty || addr.isEmpty || phone.isEmpty || price == null) {
                                ScaffoldMessenger.of(modalCtx).showSnackBar(
                                  const SnackBar(content: Text('Vui lòng điền đầy đủ tiêu đề, địa chỉ, giá thuê và SĐT liên hệ!')),
                                );
                                return;
                              }

                              // Nếu người dùng chưa up ảnh nào, gán 1 ảnh mặc định phòng sinh viên
                              final finalImages = uploadedImages.isNotEmpty
                                  ? uploadedImages
                                  : [
                                      'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=800&auto=format&fit=crop&q=80',
                                    ];

                              setFormState(() => isSubmitting = true);

                              final newRoom = {
                                'title': title,
                                'address': addr,
                                'universityNear': 'ICTU',
                                'distance': distanceController.text.trim().isNotEmpty
                                    ? distanceController.text.trim()
                                    : 'Gần cổng trường',
                                'pricePerMonth': price,
                                'deposit': double.tryParse(depositController.text.trim()) ?? price,
                                'areaM2': double.tryParse(areaController.text.trim()) ?? 22,
                                'vacantRooms': vacant,
                                'totalRooms': int.tryParse(totalRoomsController.text.trim()) ?? (vacant + 3),
                                'roomType': roomType,
                                'floor': 'Tầng 2',
                                'moveInDate': 'Vào ở ngay',
                                'images': finalImages,
                                'amenities': ['Điều hòa', 'Nóng lạnh', 'Wifi', 'Giờ tự do'],
                                'landlordName': landlordNameController.text.trim().isNotEmpty
                                    ? landlordNameController.text.trim()
                                    : _userName,
                                'landlordPhone': phone,
                                'authorEmail': _userEmail,
                                'electricityRate': 3500.0,
                                'waterRate': 20000.0,
                                'rating': 5.0,
                                'reviewsCount': 1,
                                'description': descController.text.trim(),
                                'isAvailable': true,
                                'genderPreference': 'Tất cả',
                              };

                              try {
                                final resp = await http.post(
                                  Uri.parse(ApiConfig.rooms),
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode(newRoom),
                                );
                                if (resp.statusCode == 201 || resp.statusCode == 200) {
                                  if (modalCtx.mounted) {
                                    Navigator.pop(modalCtx);
                                    ScaffoldMessenger.of(modalCtx).showSnackBar(
                                      const SnackBar(
                                        content: Text('🎉 Đã đăng tin cho thuê phòng trọ thành công!'),
                                        backgroundColor: AppColors.success,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                  _fetchRooms();
                                }
                              } catch (e) {
                                setFormState(() => isSubmitting = false);
                                if (modalCtx.mounted) {
                                  ScaffoldMessenger.of(modalCtx).showSnackBar(
                                    SnackBar(content: Text('Lỗi đăng tin: $e')),
                                  );
                                }
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Đăng Tin Cho Thuê Ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
    final filtered = _filteredRooms;
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.hotel_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thuê Trọ & Phòng Trống',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Booking phòng • Trực tiếp chủ trọ',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                // Nút Lịch hẹn của tôi
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                      tooltip: 'Lịch hẹn xem phòng của tôi',
                      onPressed: _showMyBookingsSheet,
                    ),
                    if (_myBookings.isNotEmpty)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${_myBookings.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
                // Nút Đăng phòng cho thuê
                IconButton(
                  icon: const Icon(Icons.add_home_work_rounded, color: AppColors.primary),
                  tooltip: 'Đăng tin cho thuê trọ',
                  onPressed: _openAddRoomListingModal,
                ),
              ],
            ),
      // Nút Nổi Đăng Tin Phòng Trọ Tiện Lợi (Chỉ hiển thị trên Mobile)
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_home_work_rounded),
              label: const Text('Đăng Phòng Trọ', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _openAddRoomListingModal,
            ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchRooms();
          await _fetchMyBookings();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 16,
            vertical: isDesktop ? 24 : 14,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BANNER HERO DÀNH CHO BẢN DESKTOP
                  if (isDesktop) _buildDesktopHeroBanner(),

                  // THANH TÌM KIẾM
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchKeyword = val),
                        decoration: InputDecoration(
                          hintText: 'Tìm theo đường Z115, cổng trường ICTU, căn hộ...',
                          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                          suffixIcon: _searchKeyword.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () => setState(() => _searchKeyword = ''),
                                )
                              : null,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const Divider(height: 1),

                    // Quick Chips: Khu vực
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          ..._locations.map((loc) {
                            final isSel = _selectedLocation == loc;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(loc),
                                selected: isSel,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: isSel ? Colors.white : AppColors.textSecondary,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                ),
                                backgroundColor: AppColors.background,
                                side: BorderSide(color: isSel ? AppColors.primary : AppColors.border),
                                onSelected: (val) {
                                  if (val) setState(() => _selectedLocation = loc);
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // Quick Chips: Loại phòng
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.meeting_room_rounded, size: 16, color: Colors.indigo),
                          const SizedBox(width: 6),
                          ..._roomTypes.map((t) {
                            final isSel = _selectedRoomType == t;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(t),
                                selected: isSel,
                                selectedColor: Colors.indigo,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: isSel ? Colors.white : AppColors.textSecondary,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                ),
                                backgroundColor: AppColors.background,
                                side: BorderSide(color: isSel ? Colors.indigo : AppColors.border),
                                onSelected: (val) {
                                  if (val) setState(() => _selectedRoomType = t);
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // Quick Chips: Khoảng giá
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.payments_rounded, size: 16, color: Colors.orange),
                          const SizedBox(width: 6),
                          ..._priceRanges.map((p) {
                            final isSel = _selectedPriceRange == p;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(p),
                                selected: isSel,
                                selectedColor: Colors.orange.shade700,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: isSel ? Colors.white : AppColors.textSecondary,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                ),
                                backgroundColor: AppColors.background,
                                side: BorderSide(color: isSel ? Colors.orange : AppColors.border),
                                onSelected: (val) {
                                  if (val) setState(() => _selectedPriceRange = p);
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // Switch: Chỉ hiển thị phòng còn trống
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50.withValues(alpha: 0.5),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'Chỉ tìm phòng còn trống (Đặt lịch xem ngay)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          const Spacer(),
                          Switch(
                            value: _onlyVacant,
                            activeTrackColor: Colors.green.shade200,
                            thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
                              if (states.contains(WidgetState.selected)) {
                                return Colors.green;
                              }
                              return Colors.grey.shade400;
                            }),
                            onChanged: (val) => setState(() => _onlyVacant = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // BANNER LỊCH HẸN NẾU CÓ
              if (_myBookings.isNotEmpty)
                InkWell(
                  onTap: _showMyBookingsSheet,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.buttonShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bạn có ${_myBookings.length} lịch hẹn xem phòng trọ!',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                'Gần nhất: ${_myBookings.first.bookingDate} (${_myBookings.first.timeSlot})',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.white),
                      ],
                    ),
                  ),
                ),

              // TIÊU ĐỀ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    filtered.isNotEmpty
                        ? 'Tìm thấy ${filtered.length} phòng trọ cho thuê'
                        : 'Phòng trọ cho thuê',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  if (widget.onSwitchToRoommates != null)
                    TextButton.icon(
                      onPressed: widget.onSwitchToRoommates,
                      icon: const Icon(Icons.group_rounded, size: 16),
                      label: const Text('Tìm người ở ghép', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // DANH SÁCH HOẶC GIAO DIỆN TRỐNG (EMPTY STATE CHUYÊN NGHIỆP)
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.home_work_outlined, size: 48, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Chưa Có Tin Đăng Phòng Trọ Nào',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bạn là chủ nhà hoặc sinh viên đang muốn nhượng phòng?\nHãy đăng tin đầu tiên để kết nối với các bạn sinh viên ngay!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add_home_work_rounded, size: 20),
                        label: const Text('Đăng Tin Cho Thuê Trọ Ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _openAddRoomListingModal,
                      ),
                    ],
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width >= 1050 ? 3 : (width >= 680 ? 2 : 1);

                    if (crossAxisCount == 1) {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final room = filtered[index];
                          return _buildHotelRoomCard(room, isGrid: false);
                        },
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        mainAxisExtent: 640,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final room = filtered[index];
                        return _buildHotelRoomCard(room, isGrid: true);
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  // Desktop Hero Header
  Widget _buildDesktopHeroBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Phòng Trọ Dành Cho Sinh Viên • Đại Học ICTU Thái Nguyên',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tìm Phòng Trọ & Chỗ Ở Sinh Viên Lý Tưởng',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đặt lịch hẹn xem phòng trực tiếp hoàn toàn miễn phí • Không qua môi giới • Cập nhật phòng trống thực tế',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_myBookings.isNotEmpty) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.event_note_rounded, size: 20),
                  label: Text(
                    'Lịch Hẹn Của Tôi (${_myBookings.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: _showMyBookingsSheet,
                ),
                const SizedBox(width: 12),
              ],
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.add_home_work_rounded, size: 20),
                label: const Text(
                  'Đăng Tin Cho Thuê',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: _openAddRoomListingModal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget Thẻ phòng trọ
  Widget _buildHotelRoomCard(RoomListing room, {bool isGrid = false}) {
    final isAlmostFull = room.vacantRooms == 1;
    final isMyRoom = room.authorEmail.toLowerCase() == _userEmail.toLowerCase();

    return Container(
      margin: EdgeInsets.only(bottom: isGrid ? 0 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh phòng với Badge trạng thái
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: room.images.isNotEmpty
                      ? _buildRoomImage(room.images.first)
                      : _fallbackPlaceholder(double.infinity, 200),
                ),
              ),

              // Gradient bóng mờ
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
              ),

              // Badge trạng thái phòng trống
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isAlmostFull ? Colors.redAccent : Colors.green.shade600,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAlmostFull ? Icons.local_fire_department_rounded : Icons.door_front_door_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAlmostFull
                            ? '🔥 Chỉ còn 1 phòng duy nhất!'
                            : 'Còn ${room.vacantRooms} phòng trống / ${room.totalRooms}p',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Nút xóa nếu là tin của tôi
              if (isMyRoom)
                Positioned(
                  top: 10,
                  right: 10,
                  child: InkWell(
                    onTap: () => _deleteRoom(room),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Xóa tin của tôi', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                )
              else if (room.images.length > 1)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library_rounded, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${room.images.length} ảnh',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),

              // Giá phòng
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        room.moveInDate,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: AppColors.buttonShadow,
                      ),
                      child: Text(
                        _formatPrice(room.pricePerMonth),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Nội dung chi tiết
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 15, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        room.address,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.school_rounded, size: 15, color: Colors.blueAccent),
                    const SizedBox(width: 4),
                    Text(
                      '${room.universityNear} • ${room.distance}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Specs
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSpecItem(Icons.square_foot_rounded, '${room.areaM2.toStringAsFixed(0)} m²'),
                      _buildSpecItem(Icons.stairs_rounded, room.floor),
                      _buildSpecItem(Icons.apartment_rounded, room.roomType),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Chi phí
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFeeItem('Cọc phòng', _formatCurrency(room.deposit)),
                      _buildFeeItem('Điện', '${room.electricityRate.toStringAsFixed(0)} đ/số'),
                      _buildFeeItem('Nước', '${room.waterRate.toStringAsFixed(0)} đ/khối'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Tiện ích
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: room.amenities.take(5).map((amenity) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        amenity,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Thông tin chủ nhà & Gọi / Nhắn tin
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primarySoft,
                      child: Text(
                        room.landlordName.isNotEmpty ? room.landlordName[0].toUpperCase() : 'C',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                room.landlordName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(width: 6),
                              const VerifiedBadge(text: "Người đăng"),
                            ],
                          ),
                          Text(
                            room.landlordPhone,
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.green),
                      tooltip: 'Gọi điện cho chủ nhà',
                      onPressed: () => _showCallLandlordDialog(room),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                      tooltip: 'Nhắn tin trực tiếp',
                      onPressed: () => _openChatWithLandlord(room),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ĐẶT LỊCH XEM PHÒNG
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppColors.buttonShadow,
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.calendar_month_rounded, size: 19),
                    label: const Text(
                      'Đặt Lịch Xem Phòng (Miễn Phí)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.2),
                    ),
                    onPressed: () => _openBookingDialog(room),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildFeeItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
        ),
      ],
    );
  }
}
