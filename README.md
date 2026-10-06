# 🥥 COCO App - Campus Living & Student Ecosystem

> **Nền tảng hệ sinh thái toàn diện dành cho sinh viên đại học:** Tìm trọ uy tín, kết nối bạn cùng phòng lý tưởng và giao lưu học tập / đồ án.

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Cross-Platform](https://img.shields.io/badge/Platforms-Web%20%7C%20Android%20%7C%20iOS%20%7C%20Desktop-4CAF50?style=for-the-badge)](https://flutter.dev)

---

## 🌟 Giới Thiệu (Overview)

Sinh viên đại học thường xuyên đối mặt với các khó khăn: tìm phòng trọ bị lừa đảo hoặc chi phí môi giới cao, xung đột lối sống với bạn cùng phòng ngẫu nhiên, và thiếu kênh kết nối học tập hiệu quả.

**COCO App** ra đời nhằm giải quyết triệt để các vấn đề trên với mô hình “All-in-one”:
1. **Tìm kiếm & đặt lịch xem phòng trọ sinh viên đã xác thực 100%**, minh bạch thông tin và không qua trung gian.
2. **Thuật toán ghép đôi bạn cùng phòng (AI / Lifestyle Matching)** dựa trên thói quen thức khuya/dậy sớm, độ sạch sẽ, ngân sách và sở thích.
3. **Góc học tập (Study Hub)** giúp tạo nhóm học theo môn, tìm đồng đội làm đồ án tốt nghiệp (Capstone Project), trao đổi tài liệu.
4. **Nhắn tin trực tiếp (Real-time Chat)** trao đổi nhanh chóng, bảo mật giữa sinh viên, bạn cùng phòng tiềm năng và chủ trọ.

---

## 🚀 Tính Năng Chính (Key Features)

### 1. 🏠 Phòng Trọ Sinh Viên Xác Thực (Verified Accommodations)
- Bộ lọc nâng cao: Khu vực gần trường (Đại học FPT, Bách Khoa, Quốc Gia...), khoảng giá, diện tích, tiện ích (máy lạnh, wifi, máy giặt, bếp, ban công).
- Xem chi tiết từng căn phòng, hình ảnh thực tế, tiện nghi và thông tin chủ nhà.
- Đặt lịch hẹn xem phòng trực tiếp chỉ với 1 thao tác.

### 2. 👥 Ghép Bạn Cùng Phòng Thông Minh (Roommate Finder)
- Hồ sơ phong cách sống chi tiết: Thói quen ngủ (cú đêm / dậy sớm), mức độ ngăn nắp, tính cách (hướng nội / hướng ngoại), trường học và chuyên ngành.
- Điểm tương thích (% Compatibility Score) trực quan giúp lựa chọn người bạn đồng hành phù hợp nhất.
- Bộ lọc theo giới tính, ngân sách tối đa và phong cách sống.

### 3. 📚 Campus Study Hub (Cộng Đồng Học Tập)
- Tìm bạn cùng học theo môn học, ôn thi cuối kỳ, luyện đồ án.
- Đăng bài tìm đồng đội Capstone (Flutter, Backend, AI, Mobile dev...).
- Chia sẻ và tải tài liệu môn học (Slide, đề thi mẫu, tóm tắt kiến thức).

### 4. 💬 Trò Chuyện & Kết Nối Trực Tiếp (Direct Chat)
- Khung chat thời gian thực tiện lợi.
- Đính kèm thẻ phòng hoặc gợi ý ghép đôi trực tiếp trong cuộc hội thoại.

---

## 🛠️ Công Nghệ Sử Dụng (Tech Stack)

- **Framework**: Flutter 3.x (Dart 3.x)
- **UI/UX**: Custom Design System chuẩn Design DNA (Indigo/Violet theme, Glassmorphism, Micro-interactions)
- **State & Data Management**: Provider / Local JSON Mock Engine / REST API Architecture
- **Automation & Media**: Python, Edge TTS, Selenium, FFmpeg (tự động quay màn hình & dựng pitch video)

---

## 💻 Hướng Dẫn Cài Đặt & Chạy Ứng Dụng (Getting Started)

### Yêu Cầu Môi Trường:
- Flutter SDK (>= 3.0.0)
- Google Chrome (nếu chạy Web) hoặc Android Studio / Xcode (nếu chạy Mobile)

### Các Bước Thực Hiện:

1. **Clone repository về máy**:
   ```bash
   git clone https://github.com/longbon2210/COCOAPP_1.git
   cd COCOAPP_1
   ```

2. **Cài đặt các thư viện phụ thuộc**:
   ```bash
   flutter pub get
   ```

3. **Chạy ứng dụng trên trình duyệt Web**:
   ```bash
   flutter run -d chrome
   ```
   *Hoặc click đúp file `chay_web_localhost.bat` (trên Windows).*

4. **Chạy ứng dụng trên thiết bị di động (Android / iOS)**:
   ```bash
   flutter run
   ```

---

## 🎬 Video & Tài Liệu Giới Thiệu (Pitch Demo)

- Dự án tích hợp kịch bản dựng video pitching tự động: `generate_pitch_video.py`
- Video giới thiệu hoàn chỉnh: `coco_app_pitch.mp4`

---

## 👤 Tác Giả (Author)

- **Trần Tuấn Long** ([@longbon2210](https://github.com/longbon2210))
- Email: [longbon2210@gmail.com](mailto:longbon2210@gmail.com)
