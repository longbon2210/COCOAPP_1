class RoomBooking {
  final String id;
  final String roomId;
  final String roomTitle;
  final String roomAddress;
  final String landlordName;
  final String landlordPhone;
  final String userEmail;
  final String userName;
  final String userPhone;
  final String bookingDate; // YYYY-MM-DD
  final String timeSlot; // "09:00 - 10:00 Sáng", "17:30 - 18:30 Chiều"
  final String note;
  final String status; // "Đã xác nhận", "Chờ xem phòng", "Đã hoàn thành"
  final DateTime createdAt;

  RoomBooking({
    required this.id,
    required this.roomId,
    required this.roomTitle,
    required this.roomAddress,
    required this.landlordName,
    required this.landlordPhone,
    required this.userEmail,
    required this.userName,
    required this.userPhone,
    required this.bookingDate,
    required this.timeSlot,
    required this.note,
    required this.status,
    required this.createdAt,
  });

  factory RoomBooking.fromJson(Map<String, dynamic> json) {
    return RoomBooking(
      id: json['id']?.toString() ?? 'bk_${DateTime.now().millisecondsSinceEpoch}',
      roomId: json['roomId']?.toString() ?? '',
      roomTitle: json['roomTitle']?.toString() ?? 'Phòng trọ sinh viên',
      roomAddress: json['roomAddress']?.toString() ?? 'Thái Nguyên',
      landlordName: json['landlordName']?.toString() ?? 'Chủ trọ',
      landlordPhone: json['landlordPhone']?.toString() ?? '0988 123 456',
      userEmail: json['userEmail']?.toString() ?? '',
      userName: json['userName']?.toString() ?? 'Sinh viên',
      userPhone: json['userPhone']?.toString() ?? '',
      bookingDate: json['bookingDate']?.toString() ?? '',
      timeSlot: json['timeSlot']?.toString() ?? '17:00 - 18:00',
      note: json['note']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Đã xác nhận',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'roomTitle': roomTitle,
      'roomAddress': roomAddress,
      'landlordName': landlordName,
      'landlordPhone': landlordPhone,
      'userEmail': userEmail,
      'userName': userName,
      'userPhone': userPhone,
      'bookingDate': bookingDate,
      'timeSlot': timeSlot,
      'note': note,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
