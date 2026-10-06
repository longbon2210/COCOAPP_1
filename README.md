# 🥥 COCO App - Campus Living & Student Ecosystem (Full-Stack)

> **Hệ sinh thái toàn diện dành cho sinh viên đại học:** Tìm trọ uy tín, kết nối bạn cùng phòng lý tưởng và giao lưu học tập / đồ án. Tích hợp đầy đủ cả **Frontend Flutter** và **Backend ASP.NET Core Web API (.NET 10)**.

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![.NET 10](https://img.shields.io/badge/.NET-10.0-512BD4?style=for-the-badge&logo=dotnet&logoColor=white)](https://dotnet.microsoft.com/)
[![C#](https://img.shields.io/badge/C%23-239120?style=for-the-badge&logo=c-sharp&logoColor=white)](https://learn.microsoft.com/dotnet/csharp/)
[![Cross-Platform](https://img.shields.io/badge/Platforms-Web%20%7C%20Android%20%7C%20iOS%20%7C%20Desktop-4CAF50?style=for-the-badge)](https://flutter.dev)
[![Swagger](https://img.shields.io/badge/Swagger-OpenAPI-85EA2D?style=for-the-badge&logo=swagger&logoColor=black)](http://localhost:5000/swagger)

---

## 🌟 Giới Thiệu (Overview)

Sinh viên đại học thường xuyên đối mặt với các khó khăn: tìm phòng trọ bị lừa đảo hoặc chi phí môi giới cao, xung đột lối sống với bạn cùng phòng ngẫu nhiên, và thiếu kênh kết nối học tập hiệu quả.

**COCO App** là giải pháp "All-in-one" hoàn chỉnh kết hợp sức mạnh giao diện đa nền tảng **Flutter** cùng hệ thống Backend **ASP.NET Core Web API** chuẩn doanh nghiệp:
1. **Tìm kiếm & đặt lịch xem phòng trọ xác thực 100%**: Minh bạch giá cả, hình ảnh thực tế, tiện nghi và không qua môi giới trung gian.
2. **Thuật toán ghép đôi bạn cùng phòng (AI / Lifestyle Matching)**: Quẹt thẻ hồ sơ (Like/Pass), tính điểm tương thích (% Compatibility) dựa trên giờ giấc sinh hoạt, tính cách và ngân sách.
3. **Góc học tập (Study Hub)**: Đăng tin tìm bạn làm đồ án chuyên ngành (Capstone Project), học nhóm môn học, luyện thi TOEIC.
4. **Nhắn tin trực tiếp & Real-time Chat**: Trao đổi thời gian thực giữa sinh viên, bạn cùng phòng tiềm năng và chủ trọ.

---

## 🏗️ Cấu Trúc Dự Án (Project Structure)

```text
COCOAPP_1/
├── backend/                       # Backend ASP.NET Core Web API (.NET 10)
│   ├── CoCoApp.API/
│   │   ├── Controllers/           # Auth, Rooms, Bookings, Posts, Messages, Users, Swipes
│   │   ├── Data/                  # AppDbContext, DataSeeder (tự động seed dữ liệu mẫu)
│   │   ├── Models/                # RoomListing, RoomBooking, StudyPost, User, Message...
│   │   ├── Hubs/                  # ChatHub (SignalR WebSocket)
│   │   ├── Program.cs             # Khởi tạo dịch vụ, CORS, JWT, Hybrid SQLite/SQL Server
│   │   └── appsettings.json       # Cấu hình chuỗi kết nối và JWT Key
│   ├── CoCoApp.API.slnx           # Solution Visual Studio
│   └── README.md                  # Hướng dẫn chi tiết & tài liệu API Backend
│
├── lib/                           # Frontend Flutter Application
│   ├── constants/                 # ApiConfig kết nối Backend
│   ├── models/                    # Data models Flutter
│   ├── screens/                   # Giao diện các màn hình (Tìm trọ, Đặt lịch, Ghép đôi, Study Hub...)
│   ├── services/                  # ChatService, MatchService giao tiếp REST API
│   ├── theme/                     # Design DNA (Colors, Typography, Widgets)
│   └── main.dart                  # Điểm khởi chạy ứng dụng Flutter
│
├── chay_backend.bat               # 1-Click khởi chạy Backend .NET 10 API & mở Swagger
├── chay_web_localhost.bat         # 1-Click khởi chạy Web App trên trình duyệt
├── bin/                           # Mock/Proxy server hỗ trợ kiểm thử
└── README.md                      # Tài liệu tổng quan dự án
```

---

## 🛠️ Công Nghệ Sử Dụng (Tech Stack)

### Frontend:
- **Framework**: Flutter 3.x (Dart 3.x)
- **UI/UX**: Custom Design System chuẩn Design DNA (Indigo/Violet theme, Glassmorphism, Micro-interactions)
- **Platforms**: Web, Android, iOS, Windows, macOS, Linux

### Backend:
- **Nền tảng**: ASP.NET Core Web API (.NET 10.0)
- **Ngôn ngữ**: C# 13
- **ORM & Database**: Entity Framework Core 10 (Hỗ trợ SQLite chạy offline cục bộ & SQL Server sản xuất)
- **Bảo mật**: JWT (JSON Web Token) Authentication, mã hóa mật khẩu `BCrypt`
- **Real-time**: ASP.NET Core SignalR WebSocket
- **API Documentation**: Swagger / OpenAPI trực quan hóa

---

## 💻 Hướng Dẫn Khởi Chạy Ứng Dụng Hoàn Chỉnh

### 1. Khởi chạy Backend (.NET Web API)

> **Yêu cầu**: Máy tính đã cài [.NET 10 SDK](https://dotnet.microsoft.com/)

**Cách 1 (Nhanh nhất trên Windows):**
- Click đúp vào file `chay_backend.bat` ở thư mục gốc.

**Cách 2 (Sử dụng lệnh Terminal):**
```bash
cd backend/CoCoApp.API
dotnet run
```
- Backend sẽ tự động khởi động tại: `http://localhost:5000`
- Giao diện trực quan Swagger UI: [http://localhost:5000/swagger](http://localhost:5000/swagger)
- *Ghi chú: Backend tự động tạo cơ sở dữ liệu SQLite cục bộ `cocoapp.db` và nạp sẵn dữ liệu mẫu thực tế, bạn không cần phải cấu hình thêm database!*

---

### 2. Khởi chạy Frontend (Flutter App)

> **Yêu cầu**: Máy tính đã cài [Flutter SDK](https://flutter.dev) (>= 3.0.0)

1. Cài đặt các thư viện phụ thuộc:
   ```bash
   flutter pub get
   ```

2. Chạy ứng dụng trên trình duyệt Web (Chrome):
   ```bash
   flutter run -d chrome
   ```
   *(Hoặc click đúp file `chay_web_localhost.bat`)*

3. Chạy ứng dụng trên thiết bị di động (Android / iOS):
   ```bash
   flutter run
   ```

---

## 📋 Danh Sách Endpoints REST API

| Nhóm chức năng | Endpoint | Phương thức | Chi tiết |
|---------------|----------|------------|---------|
| **Xác thực** | `/api/auth/register` | `POST` | Đăng ký tài khoản sinh viên |
| **Xác thực** | `/api/auth/login` | `POST` | Đăng nhập nhận JWT Token |
| **Người dùng** | `/api/users` | `GET` | Danh sách sinh viên tìm bạn cùng phòng |
| **Hồ sơ** | `/api/users/profile` | `GET`, `PUT` | Xem & cập nhật thông tin cá nhân |
| **Phòng trọ** | `/api/rooms` | `GET`, `POST`, `DELETE` | Tra cứu, đăng tin & xóa phòng trọ |
| **Đặt lịch** | `/api/bookings` | `GET`, `POST`, `DELETE` | Đặt lịch hẹn xem phòng với chủ trọ |
| **Học tập** | `/api/posts` | `GET`, `POST`, `DELETE` | Đăng bài & tìm đồng đội Capstone / nhóm học |
| **Ghép đôi** | `/api/swipes` | `POST` | Quẹt thẻ tương tác & kiểm tra tương hợp |
| **Tin nhắn** | `/api/messages` | `GET`, `POST` | Nhắn tin trực tiếp giữa 2 người dùng |
| **WebSocket** | `/chatHub` | `WS` | Kênh SignalR cho chat thời gian thực |

---

## 👤 Tác Giả (Author)

- **Trần Tuấn Long** ([@longbon2210](https://github.com/longbon2210))
- Email: [longbon2210@gmail.com](mailto:longbon2210@gmail.com)
