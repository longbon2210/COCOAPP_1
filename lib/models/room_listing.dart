class RoomListing {
  final String id;
  final String title;
  final String address;
  final String universityNear;
  final String distance;
  final double pricePerMonth;
  final double deposit;
  final double areaM2;
  final int vacantRooms;
  final int totalRooms;
  final String roomType;
  final String floor;
  final String moveInDate;
  final List<String> images;
  final List<String> amenities;
  final String landlordName;
  final String landlordPhone;
  final String authorEmail;
  final double electricityRate;
  final double waterRate;
  final double rating;
  final int reviewsCount;
  final String description;
  final bool isAvailable;
  final String genderPreference;
  bool isBookmarked;

  RoomListing({
    required this.id,
    required this.title,
    required this.address,
    required this.universityNear,
    required this.distance,
    required this.pricePerMonth,
    required this.deposit,
    required this.areaM2,
    required this.vacantRooms,
    required this.totalRooms,
    required this.roomType,
    required this.floor,
    required this.moveInDate,
    required this.images,
    required this.amenities,
    required this.landlordName,
    required this.landlordPhone,
    required this.authorEmail,
    required this.electricityRate,
    required this.waterRate,
    required this.rating,
    required this.reviewsCount,
    required this.description,
    required this.isAvailable,
    required this.genderPreference,
    this.isBookmarked = false,
  });

  factory RoomListing.fromJson(Map<String, dynamic> json) {
    final price = (json['pricePerMonth'] is num)
        ? (json['pricePerMonth'] as num).toDouble()
        : double.tryParse(json['pricePerMonth']?.toString() ?? '1800000') ?? 1800000;

    return RoomListing(
      id: json['id']?.toString() ?? 'room_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? '',
      address: json['address']?.toString() ?? 'Thái Nguyên',
      universityNear: json['universityNear']?.toString() ?? 'ICTU',
      distance: json['distance']?.toString() ?? 'Cách cổng trường 300m',
      pricePerMonth: price,
      deposit: (json['deposit'] is num)
          ? (json['deposit'] as num).toDouble()
          : double.tryParse(json['deposit']?.toString() ?? price.toString()) ?? price,
      areaM2: (json['areaM2'] is num)
          ? (json['areaM2'] as num).toDouble()
          : double.tryParse(json['areaM2']?.toString() ?? '24') ?? 24,
      vacantRooms: (json['vacantRooms'] is int)
          ? json['vacantRooms']
          : int.tryParse(json['vacantRooms']?.toString() ?? '2') ?? 2,
      totalRooms: (json['totalRooms'] is int)
          ? json['totalRooms']
          : int.tryParse(json['totalRooms']?.toString() ?? '8') ?? 8,
      roomType: json['roomType']?.toString() ?? 'Phòng khép kín ban công',
      floor: json['floor']?.toString() ?? 'Tầng 2',
      moveInDate: json['moveInDate']?.toString() ?? 'Vào ở ngay hôm nay',
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [
        'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=800&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800&auto=format&fit=crop&q=80',
      ],
      amenities: (json['amenities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [
        'Điều hòa',
        'Nóng lạnh',
        'Giờ tự do 24/7',
        'Khóa vân tay',
        'Wifi tốc độ cao',
      ],
      landlordName: json['landlordName']?.toString() ?? 'Bác Hùng (Chủ nhà)',
      landlordPhone: json['landlordPhone']?.toString() ?? '0987 654 321',
      authorEmail: json['authorEmail']?.toString() ?? 'chutro@gmail.com',
      electricityRate: (json['electricityRate'] is num)
          ? (json['electricityRate'] as num).toDouble()
          : double.tryParse(json['electricityRate']?.toString() ?? '3500') ?? 3500,
      waterRate: (json['waterRate'] is num)
          ? (json['waterRate'] as num).toDouble()
          : double.tryParse(json['waterRate']?.toString() ?? '25000') ?? 25000,
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : double.tryParse(json['rating']?.toString() ?? '4.9') ?? 4.9,
      reviewsCount: (json['reviewsCount'] is int)
          ? json['reviewsCount']
          : int.tryParse(json['reviewsCount']?.toString() ?? '18') ?? 18,
      description: json['description']?.toString() ?? '',
      isAvailable: json['isAvailable'] != false,
      genderPreference: json['genderPreference']?.toString() ?? 'Tất cả',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'address': address,
      'universityNear': universityNear,
      'distance': distance,
      'pricePerMonth': pricePerMonth,
      'deposit': deposit,
      'areaM2': areaM2,
      'vacantRooms': vacantRooms,
      'totalRooms': totalRooms,
      'roomType': roomType,
      'floor': floor,
      'moveInDate': moveInDate,
      'images': images,
      'amenities': amenities,
      'landlordName': landlordName,
      'landlordPhone': landlordPhone,
      'authorEmail': authorEmail,
      'electricityRate': electricityRate,
      'waterRate': waterRate,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'description': description,
      'isAvailable': isAvailable,
      'genderPreference': genderPreference,
    };
  }

  static List<RoomListing> getSampleRooms() {
    return [
      RoomListing(
        id: "room_sample_1",
        title: "Phòng Studio Ban Công Thoáng Mát - Ngõ 18 Đường Z115 (Cách Cổng ICTU 250m)",
        address: "Số 28, Ngõ 18 Đường Z115, Xã Quyết Thắng, TP. Thái Nguyên",
        universityNear: "Đại học CNTT & Truyền Thông (ICTU)",
        distance: "Cách cổng trường 250m",
        pricePerMonth: 2200000,
        deposit: 2000000,
        areaM2: 26,
        vacantRooms: 2,
        totalRooms: 8,
        roomType: "Studio ban công",
        floor: "Tầng 3",
        moveInDate: "Vào ở ngay",
        images: [
          "https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=900&auto=format&fit=crop&q=80",
          "https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=900&auto=format&fit=crop&q=80",
        ],
        amenities: [
          "Điều hòa Inverter",
          "Nóng lạnh",
          "Ban công riêng",
          "Khóa vân tay",
          "Giờ giấc tự do",
          "Wifi 150Mbps"
        ],
        landlordName: "Cô Lan (Chính chủ)",
        landlordPhone: "0988 234 567",
        authorEmail: "lan.nhatro@gmail.com",
        electricityRate: 3500,
        waterRate: 25000,
        rating: 4.9,
        reviewsCount: 18,
        description: "Phòng khép kín ban công đón gió tự nhiên, đầy đủ tiện nghi điều hòa, bình nóng lạnh, giường đệm cao cấp, bàn học đôi cho sinh viên.",
        isAvailable: true,
        genderPreference: "Tất cả",
      ),
      RoomListing(
        id: "room_sample_2",
        title: "Căn Hộ Mini Full Đồ Bếp Riêng Hút Mùi - Mặt Đường Tân Thịnh Đối Diện KTX",
        address: "Số 104 Đường Tân Thịnh, Phường Tân Thịnh, TP. Thái Nguyên",
        universityNear: "Đại học CNTT & Truyền Thông (ICTU)",
        distance: "Cách cổng trường 400m",
        pricePerMonth: 2800000,
        deposit: 2500000,
        areaM2: 32,
        vacantRooms: 1,
        totalRooms: 12,
        roomType: "Căn hộ mini",
        floor: "Tầng 2 (Có thang máy)",
        moveInDate: "Còn 1 phòng duy nhất",
        images: [
          "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=900&auto=format&fit=crop&q=80",
          "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=900&auto=format&fit=crop&q=80",
        ],
        amenities: [
          "Bếp riêng hút mùi",
          "Tủ lạnh Inverter",
          "Điều hòa",
          "Thang máy",
          "Camera 24/7"
        ],
        landlordName: "Chú Hùng (Quản lý tòa nhà)",
        landlordPhone: "0977 890 123",
        authorEmail: "hung.apartments@gmail.com",
        electricityRate: 3800,
        waterRate: 28000,
        rating: 5.0,
        reviewsCount: 24,
        description: "Căn hộ mini cao cấp thiết kế hiện đại chuẩn phong cách sống Gen-Z. Bếp riêng tách biệt không lo ám mùi vào phòng ngủ.",
        isAvailable: true,
        genderPreference: "Tất cả",
      ),
    ];
  }
}
