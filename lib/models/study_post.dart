class StudyPost {
  final String id;
  final String authorName;
  final String authorEmail;
  final String authorAvatar;
  final String university;
  final String title;
  final String description;
  final String subject;
  final List<String> tags;
  final int membersCurrent;
  final int membersNeeded;
  final DateTime createdAt;
  final int partnerId;

  StudyPost({
    required this.id,
    required this.authorName,
    required this.authorEmail,
    required this.authorAvatar,
    required this.university,
    required this.title,
    required this.description,
    required this.subject,
    required this.tags,
    required this.membersCurrent,
    required this.membersNeeded,
    required this.createdAt,
    required this.partnerId,
  });

  factory StudyPost.fromJson(Map<String, dynamic> json) {
    return StudyPost(
      id: json['id']?.toString() ?? 'post_${DateTime.now().millisecondsSinceEpoch}',
      authorName: json['authorName']?.toString() ?? 'Sinh viên',
      authorEmail: json['authorEmail']?.toString() ?? 'sinhvien@ictu.edu.vn',
      authorAvatar: json['authorAvatar']?.toString() ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
      university: json['university']?.toString() ?? 'ICTU',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      subject: json['subject']?.toString() ?? 'Học tập',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['Học tập', 'ICTU'],
      membersCurrent: (json['membersCurrent'] is int)
          ? json['membersCurrent']
          : int.tryParse(json['membersCurrent']?.toString() ?? '1') ?? 1,
      membersNeeded: (json['membersNeeded'] is int)
          ? json['membersNeeded']
          : int.tryParse(json['membersNeeded']?.toString() ?? '3') ?? 3,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      partnerId: (json['partnerId'] is int)
          ? json['partnerId']
          : int.tryParse(json['partnerId']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'authorAvatar': authorAvatar,
      'university': university,
      'title': title,
      'description': description,
      'subject': subject,
      'tags': tags,
      'membersCurrent': membersCurrent,
      'membersNeeded': membersNeeded,
      'createdAt': createdAt.toIso8601String(),
      'partnerId': partnerId,
    };
  }

  static List<StudyPost> getSamplePosts() {
    return [
      StudyPost(
        id: "post_sample_1",
        authorName: "Nguyễn Hoàng Nam",
        authorEmail: "nam.nh.k21@ictu.edu.vn",
        authorAvatar: "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=500",
        university: "Đại học CNTT & Truyền Thông (ICTU)",
        title: "Tìm 1 bạn cùng làm Đồ Án Chuyên Ngành - Xây dựng Ứng dụng Di động Flutter",
        description: "Nhóm mình hiện đã có 2 người, đề tài về ứng dụng quản lý phòng trọ sinh viên. Cần thêm 1 bạn phụ trách giao diện UI/UX Flutter.",
        subject: "Đồ án CNTT",
        tags: ["Flutter", "Dart", "Đồ án K21", "ICTU"],
        membersCurrent: 2,
        membersNeeded: 3,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        partnerId: 101,
      ),
      StudyPost(
        id: "post_sample_2",
        authorName: "Trần Thu Trang",
        authorEmail: "trang.tt.k22@ictu.edu.vn",
        authorAvatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500",
        university: "Đại học CNTT & Truyền Thông (ICTU)",
        title: "Lập nhóm 3-4 bạn cùng tự học & giải đề TOEIC mục tiêu 650+ chuẩn đầu ra",
        description: "Nhóm học online buổi tối (20h - 22h) các ngày thứ 3, 5, 7 qua Google Meet. Mỗi buổi cùng giải 1 đề ETS và chữa từ vựng.",
        subject: "Ngoại ngữ & TOEIC",
        tags: ["TOEIC", "Tiếng Anh", "Luyện đề", "Đầu ra chuẩn"],
        membersCurrent: 2,
        membersNeeded: 4,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        partnerId: 102,
      ),
      StudyPost(
        id: "post_sample_3",
        authorName: "Lê Văn Quân",
        authorEmail: "quan.lv.k21@ictu.edu.vn",
        authorAvatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500",
        university: "Đại học CNTT & Truyền Thông (ICTU)",
        title: "Tìm bạn học chung môn Cấu trúc dữ liệu & Thuật toán + Ôn thi cuối kỳ",
        description: "Mình đang ôn tập phần cây nhị phân, đồ thị và quy hoạch động. Muốn tìm bạn học cùng ngồi thư viện trường hoặc quán cafe gần Z115.",
        subject: "Khoa học máy tính",
        tags: ["C++", "Thuật toán", "Cấu trúc dữ liệu", "Ôn thi"],
        membersCurrent: 1,
        membersNeeded: 2,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        partnerId: 103,
      ),
    ];
  }
}
