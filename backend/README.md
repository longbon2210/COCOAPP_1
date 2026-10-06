# 🥥 COCO App - Backend Web API (.NET 10)

> Hệ thống Backend RESTful Web API và Real-time SignalR cho nền tảng hệ sinh thái sinh viên **COCO App**.

[![.NET 10](https://img.shields.io/badge/.NET-10.0-512BD4?style=for-the-badge&logo=dotnet&logoColor=white)](https://dotnet.microsoft.com/)
[![C#](https://img.shields.io/badge/C%23-239120?style=for-the-badge&logo=c-sharp&logoColor=white)](https://learn.microsoft.com/dotnet/csharp/)
[![Entity Framework Core](https://img.shields.io/badge/EF%20Core-10.0-512BD4?style=for-the-badge)](https://learn.microsoft.com/ef/core/)
[![Swagger](https://img.shields.io/badge/Swagger-OpenAPI-85EA2D?style=for-the-badge&logo=swagger&logoColor=black)](http://localhost:5000/swagger)

---

## 🌟 Giới Thiệu & Kiến Trúc

Backend được phát triển bằng **ASP.NET Core Web API (.NET 10)** với kiến trúc tối ưu hóa hiệu năng cao, hỗ trợ đầy đủ toàn bộ tính năng của COCO App:

1. **Xác thực & Người dùng (Authentication & Users)**: Đăng ký, đăng nhập bảo mật băm mật khẩu `BCrypt`, cấp thẻ `JWT Bearer Token`, quản lý và cập nhật hồ sơ cá nhân sinh viên.
2. **Tìm trọ & Quản lý phòng trọ (Rooms API)**: Danh sách phòng trọ sinh viên gần trường ICTU / Thái Nguyên, lọc tiện ích, chi tiết phòng, giá điện nước.
3. **Đặt lịch xem phòng trọ (Bookings API)**: Đặt hẹn ngày giờ trực tiếp với chủ trọ, quản lý trạng thái lịch xem phòng và hủy lịch.
4. **Cộng đồng học tập (Campus Study Hub)**: Đăng bài tìm đồng đội Capstone / đồ án môn học, ôn thi TOEIC, trao đổi tài liệu học tập.
5. **Ghép bạn cùng phòng (Roommate Matching & Swipes)**: Thuật toán quẹt hồ sơ (Like / Pass), tự động ghi nhận Tương hợp (Match) 2 chiều khi cả hai sinh viên cùng thích nhau.
6. **Nhắn tin trực tiếp (Chat & Messaging)**: Lưu trữ lịch sử cuộc hội thoại thực tế giữa các sinh viên, tích hợp `SignalR ChatHub` cho thông báo thời gian thực.
7. **Cơ sở dữ liệu linh hoạt (Hybrid Database)**: 
   - **Tự động chạy cục bộ (Offline)**: Tự tạo cơ sở dữ liệu `SQLite` (`cocoapp.db`) và nạp sẵn dữ liệu mẫu thực tế của sinh viên & phòng trọ quanh trường ICTU.
   - **Môi trường sản xuất**: Hỗ trợ kết nối `SQL Server` (Somee / Azure / On-premise) chỉ với 1 chuỗi kết nối trong `appsettings.json` hoặc User Secrets.

---

## 📋 Danh Sách Endpoints Chính

| Phân hệ | Phương thức | Endpoint | Mô tả |
|---------|------------|----------|-------|
| **Auth** | `POST` | `/api/auth/register` | Đăng ký tài khoản sinh viên mới |
| **Auth** | `POST` | `/api/auth/login` | Đăng nhập và nhận JWT Token |
| **Users** | `GET` | `/api/users` | Lấy danh sách hồ sơ sinh viên để tìm bạn cùng phòng |
| **Users** | `GET` / `PUT` | `/api/users/profile` | Xem và cập nhật hồ sơ chi tiết của bản thân |
| **Rooms** | `GET` | `/api/rooms` | Lấy toàn bộ danh sách phòng trọ sinh viên xác thực |
| **Rooms** | `POST` | `/api/rooms` | Đăng bài phòng trọ mới |
| **Rooms** | `DELETE` | `/api/rooms?id={id}` | Xóa tin đăng phòng trọ |
| **Bookings** | `GET` | `/api/bookings?userEmail={email}` | Lấy danh sách lịch hẹn xem phòng của sinh viên |
| **Bookings** | `POST` | `/api/bookings` | Tạo lịch hẹn xem phòng trọ mới |
| **Bookings** | `DELETE` | `/api/bookings?id={id}` | Hủy lịch hẹn xem phòng |
| **Study Hub**| `GET` | `/api/posts` | Danh sách bài đăng tìm nhóm học / Capstone |
| **Study Hub**| `POST` | `/api/posts` | Tạo bài đăng học tập mới |
| **Study Hub**| `DELETE`| `/api/posts?id={id}` | Xóa bài đăng học tập |
| **Matching** | `POST` | `/api/swipes` | Quẹt thẻ sinh viên (Thích / Bỏ qua) & tạo Match |
| **Matching** | `GET` | `/api/match/my-matches` | Lấy danh sách bạn bè đã Match tương hợp |
| **Messages** | `GET` | `/api/messages?user1={u1}&user2={u2}` | Lấy lịch sử trò chuyện giữa 2 sinh viên |
| **Messages** | `GET` | `/api/messages?myEmail={email}` | Lấy toàn bộ tin nhắn liên quan đến sinh viên |
| **Messages** | `POST` | `/api/messages` | Gửi tin nhắn mới |
| **SignalR** | `WS` | `/chatHub` | Real-time WebSocket Hub cho tin nhắn tức thời |

---

## 🚀 Hướng Dẫn Chạy Backend

### Yêu Cầu Môi Trường:
- **.NET SDK 10.0** (hoặc Visual Studio 2022 v17.12 trở lên)

### Các Bước Thực Hiện:

1. **Mở thư mục backend**:
   ```bash
   cd backend/CoCoApp.API
   ```

2. **Chạy ứng dụng**:
   ```bash
   dotnet run
   ```

3. **Truy cập Swagger UI (Trực quan hóa API)**:
   Mở trình duyệt truy cập: [http://localhost:5000/swagger](http://localhost:5000/swagger)

---

## ⚙️ Cấu Hình Database

File `appsettings.json`:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Data Source=cocoapp.db"
  },
  "Jwt": {
    "Key": "MotChuoiKyTuBiMatRatDaiVaKhoDoanChoDuAnCocoApp123!@#"
  }
}
```

- Nếu muốn kết nối SQL Server (ví dụ Somee): Cung cấp chuỗi kết nối SQL Server vào `ConnectionStrings:DefaultConnection`.
- Nếu để trống hoặc dùng `Data Source=cocoapp.db`: Hệ thống sẽ tự động sử dụng SQLite cục bộ, tự động khởi tạo bảng và seed dữ liệu mẫu sinh viên & phòng trọ ngay khi khởi động.
