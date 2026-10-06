class UserProfile {
  final int id;
  final String email;
  final String name;
  final String university;
  final String major;
  final String avatarUrl;
  final String bio;
  final double rentalBudget;
  final String roomLocation;
  final String roomStatus; // 'Đang tìm bạn ở ghép' hoặc 'Đã có phòng sẵn'
  final String gender;
  final bool isSmoker;
  final bool hasPet;
  final String studyGoal;
  final List<String> studySkills;
  final List<String> lifestyleTags;
  final int compatibilityScore;
  final bool isOnline;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.university,
    required this.major,
    required this.avatarUrl,
    required this.bio,
    required this.rentalBudget,
    required this.roomLocation,
    required this.roomStatus,
    required this.gender,
    required this.isSmoker,
    required this.hasPet,
    required this.studyGoal,
    required this.studySkills,
    required this.lifestyleTags,
    required this.compatibilityScore,
    this.isOnline = true,
  });

  int get matchPercentage => compatibilityScore;
  List<String> get tags => [...lifestyleTags, ...studySkills];

  factory UserProfile.fromApiJson(Map<String, dynamic> json, {int index = 0}) {
    final int id = json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0;
    final String email = json['email']?.toString() ?? 'sinhvien@ictu.edu.vn';
    final String university = json['university']?.toString().isNotEmpty == true
        ? json['university']!
        : 'ICTU';
    final String major = json['major']?.toString().isNotEmpty == true
        ? json['major']!
        : 'Công nghệ thông tin';

    final avatars = [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=500&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=500&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=500&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500&auto=format&fit=crop&q=80',
    ];

    final names = [
      'Hoàng Minh Châu',
      'Trần Tuấn Kiệt',
      'Nguyễn Thanh Thảo',
      'Lê Quang Hải',
      'Phạm Thu Uyên',
      'Vũ Đức Huy',
      'Đặng Linh Chi',
      'Bùi Nhật Minh',
      'Nguyễn Phương Anh',
    ];

    final locations = [
      'Khu vực Z115, gần cổng trường ICTU',
      'Đường Tân Thịnh, cách trường 800m',
      'Khu trọ sinh viên Quang Trung',
      'Khu chung cư Tecco / gần TNUT',
      'Gần ngã tư Đồng Quang',
    ];

    final roomStatuses = [
      'Đang tìm bạn ở ghép chung phòng',
      'Đã có phòng sẵn (đủ đồ), cần tìm 1 bạn',
      'Đang tìm trọ mới để thuê cùng',
      'Đã có phòng sẵn (điều hòa, máy giặt)',
    ];

    final goals = [
      'Cần tìm bạn học cùng nhóm đồ án CNTT & ôn thi học kỳ',
      'Muốn học nhóm tiếng Anh giao tiếp & luyện TOEIC 650+',
      'Làm bài tập lớn môn Cơ sở dữ liệu & Lập trình Web',
      'Chia sẻ tài liệu học tập, cùng ôn thi đạt học bổng',
      'Tìm bạn học cùng ngành KTPM để code dự án thực tế',
    ];

    final skillSets = [
      ['Flutter', 'Dart', 'Git', 'Thiết kế UI'],
      ['C#', 'ASP.NET', 'SQL Server', 'OOP'],
      ['Python', 'Phân tích dữ liệu', 'Machine Learning'],
      ['HTML/CSS', 'JavaScript', 'React', 'NodeJS'],
      ['Tiếng Anh', 'Thuyết trình', 'Làm việc nhóm'],
    ];

    final isSmoker = index % 4 == 0;
    final hasPet = index % 3 == 0;
    final budget = 1500000.0 + (index % 3) * 500000.0;

    final lifestyles = [
      isSmoker ? '🚬 Có hút thuốc' : '🚭 Không hút thuốc',
      hasPet ? '🐾 Có nuôi pet' : '🚫 Không nuôi pet',
      index % 2 == 0 ? '🌙 Ngủ trước 24h' : '☕ Cú đêm học bài',
      '📚 Cần không gian yên tĩnh',
      '🍳 Nấu ăn tại phòng',
    ];

    return UserProfile(
      id: id,
      email: email,
      name: names[index % names.length],
      university: university,
      major: major,
      avatarUrl: avatars[index % avatars.length],
      bio: 'Sinh viên năm 3 chuyên ngành $major tại $university. Mục tiêu học tập chăm chỉ, lối sống tự lập, có ý thức giữ gìn vệ sinh chung.',
      rentalBudget: budget,
      roomLocation: locations[index % locations.length],
      roomStatus: roomStatuses[index % roomStatuses.length],
      gender: index % 2 == 0 ? 'Nữ' : 'Nam',
      isSmoker: isSmoker,
      hasPet: hasPet,
      studyGoal: goals[index % goals.length],
      studySkills: skillSets[index % skillSets.length],
      lifestyleTags: lifestyles,
      compatibilityScore: 89 + (index * 4) % 11,
      isOnline: index % 2 == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'university': university,
    'major': major,
    'avatarUrl': avatarUrl,
    'bio': bio,
    'rentalBudget': rentalBudget,
    'roomLocation': roomLocation,
    'roomStatus': roomStatus,
    'gender': gender,
    'isSmoker': isSmoker,
    'hasPet': hasPet,
    'studyGoal': studyGoal,
    'studySkills': studySkills,
    'lifestyleTags': lifestyleTags,
    'compatibilityScore': compatibilityScore,
    'isOnline': isOnline,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as int? ?? 0,
    email: json['email']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Sinh viên',
    university: json['university']?.toString() ?? 'ICTU',
    major: json['major']?.toString() ?? 'Công nghệ thông tin',
    avatarUrl: json['avatarUrl']?.toString() ?? '',
    bio: json['bio']?.toString() ?? '',
    rentalBudget: (json['rentalBudget'] as num?)?.toDouble() ?? 2000000,
    roomLocation: json['roomLocation']?.toString() ?? 'Gần trường',
    roomStatus: json['roomStatus']?.toString() ?? 'Đang tìm bạn ở ghép',
    gender: json['gender']?.toString() ?? 'Nam',
    isSmoker: json['isSmoker'] == true,
    hasPet: json['hasPet'] == true,
    studyGoal: json['studyGoal']?.toString() ?? 'Cùng học tập và chia sẻ tài liệu',
    studySkills: (json['studySkills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['Tin học văn phòng'],
    lifestyleTags: (json['lifestyleTags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['Sạch sẽ', 'Yên tĩnh'],
    compatibilityScore: json['compatibilityScore'] as int? ?? 92,
    isOnline: json['isOnline'] == true,
  );

  static List<UserProfile> getSampleProfiles() {
    return List.generate(8, (i) => UserProfile.fromApiJson({
      'id': i + 1,
      'email': 'sinhvien_${i + 1}@ictu.edu.vn',
      'university': 'Đại học CNTT & Truyền Thông (ICTU)',
    }, index: i));
  }
}
