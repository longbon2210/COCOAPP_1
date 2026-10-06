class StudyMaterial {
  final String id;
  final String title;
  final String courseName;
  final String fileType; // PDF, DOCX, ZIP
  final String fileSize;
  final String authorName;
  final String university;
  final int downloadCount;
  final int likesCount;
  final double rating;
  final String description;
  final DateTime uploadDate;

  StudyMaterial({
    required this.id,
    required this.title,
    required this.courseName,
    required this.fileType,
    required this.fileSize,
    required this.authorName,
    required this.university,
    required this.downloadCount,
    required this.likesCount,
    required this.rating,
    required this.description,
    required this.uploadDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'courseName': courseName,
    'fileType': fileType,
    'fileSize': fileSize,
    'authorName': authorName,
    'university': university,
    'downloadCount': downloadCount,
    'likesCount': likesCount,
    'rating': rating,
    'description': description,
    'uploadDate': uploadDate.toIso8601String(),
  };

  factory StudyMaterial.fromJson(Map<String, dynamic> json) => StudyMaterial(
    id: json['id']?.toString() ?? 'mat_${DateTime.now().millisecondsSinceEpoch}',
    title: json['title']?.toString() ?? '',
    courseName: json['courseName']?.toString() ?? 'Chung',
    fileType: json['fileType']?.toString() ?? 'PDF',
    fileSize: json['fileSize']?.toString() ?? '2.4 MB',
    authorName: json['authorName']?.toString() ?? 'Sinh viên ICTU',
    university: json['university']?.toString() ?? 'ICTU',
    downloadCount: (json['downloadCount'] as num?)?.toInt() ?? 128,
    likesCount: (json['likesCount'] as num?)?.toInt() ?? 45,
    rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
    description: json['description']?.toString() ?? '',
    uploadDate: DateTime.tryParse(json['uploadDate']?.toString() ?? '') ?? DateTime.now(),
  );

  static List<StudyMaterial> getSampleMaterials() {
    return [
      StudyMaterial(
        id: "mat_1",
        title: "Bộ Đề Thi & Đáp Án Môn Cơ Sở Dữ Liệu Các Kỳ (ICTU)",
        courseName: "Cơ sở dữ liệu",
        fileType: "PDF",
        fileSize: "4.8 MB",
        authorName: "Khoa CNTT - ICTU",
        university: "ĐH CNTT & Truyền Thông",
        downloadCount: 382,
        likesCount: 114,
        rating: 4.9,
        description: "Tổng hợp 6 bộ đề thi trắc nghiệm và tự luận kèm lời giải chi tiết môn Cơ sở dữ liệu qua các kỳ thi.",
        uploadDate: DateTime.now().subtract(const Duration(days: 3)),
      ),
      StudyMaterial(
        id: "mat_2",
        title: "Full Slide & Source Code Mẫu Lập Trình Ứng Dụng Flutter",
        courseName: "Lập trình Di động",
        fileType: "ZIP",
        fileSize: "18.5 MB",
        authorName: "CLB Lập trình ICTU",
        university: "ĐH CNTT & Truyền Thông",
        downloadCount: 520,
        likesCount: 198,
        rating: 5.0,
        description: "Bộ tài liệu học Flutter từ cơ bản đến nâng cao: Widget, State Management (Provider, Bloc), REST API và SignalR.",
        uploadDate: DateTime.now().subtract(const Duration(days: 6)),
      ),
      StudyMaterial(
        id: "mat_3",
        title: "Bộ 600 Từ Vựng & 10 Đề Luyện Thi TOEIC Chuẩn Đầu Ra",
        courseName: "Tiếng Anh & TOEIC",
        fileType: "PDF",
        fileSize: "8.2 MB",
        authorName: "Trần Thu Trang",
        university: "ĐH CNTT & Truyền Thông",
        downloadCount: 640,
        likesCount: 230,
        rating: 4.8,
        description: "Tài liệu tự học TOEIC cô đọng từ vựng then chốt, ngữ pháp trọng tâm và mẹo nghe Part 1-4 sát thực tế.",
        uploadDate: DateTime.now().subtract(const Duration(days: 10)),
      ),
      StudyMaterial(
        id: "mat_4",
        title: "Giáo Trình & Bài Tập Lớn Kiến Trúc Máy Tính & Vi Xử Lý",
        courseName: "Kiến trúc máy tính",
        fileType: "PDF",
        fileSize: "6.1 MB",
        authorName: "Lê Văn Quân",
        university: "ĐH CNTT & Truyền Thông",
        downloadCount: 215,
        likesCount: 68,
        rating: 4.7,
        description: "Tài liệu giải bài tập tuần và gợi ý đề cương ôn tập môn Kiến trúc máy tính.",
        uploadDate: DateTime.now().subtract(const Duration(days: 14)),
      ),
    ];
  }
}
