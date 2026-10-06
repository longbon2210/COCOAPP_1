using CocoApp.API.Models;
using Microsoft.EntityFrameworkCore;

namespace CocoApp.API.Data
{
	public static class DataSeeder
	{
		public static void EnsureTablesExist(AppDbContext context, bool isSqlServer)
		{
			if (!isSqlServer)
			{
				context.Database.EnsureCreated();
				return;
			}

			try
			{
				// Tự động kiểm tra và tạo bảng Rooms trên SQL Server nếu chưa có
				context.Database.ExecuteSqlRaw(@"
					IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Rooms' AND xtype='U')
					CREATE TABLE Rooms (
						Id NVARCHAR(100) PRIMARY KEY,
						Title NVARCHAR(500) NOT NULL,
						Address NVARCHAR(500) NOT NULL,
						UniversityNear NVARCHAR(200) NOT NULL,
						Distance NVARCHAR(100) NOT NULL,
						PricePerMonth FLOAT NOT NULL,
						Deposit FLOAT NOT NULL,
						AreaM2 FLOAT NOT NULL,
						VacantRooms INT NOT NULL,
						TotalRooms INT NOT NULL,
						RoomType NVARCHAR(100) NOT NULL,
						Floor NVARCHAR(50) NOT NULL,
						MoveInDate NVARCHAR(100) NOT NULL,
						Images NVARCHAR(MAX) NOT NULL,
						Amenities NVARCHAR(MAX) NOT NULL,
						LandlordName NVARCHAR(200) NOT NULL,
						LandlordPhone NVARCHAR(50) NOT NULL,
						AuthorEmail NVARCHAR(200) NOT NULL,
						ElectricityRate FLOAT NOT NULL,
						WaterRate FLOAT NOT NULL,
						Rating FLOAT NOT NULL,
						ReviewsCount INT NOT NULL,
						Description NVARCHAR(MAX) NOT NULL,
						IsAvailable BIT NOT NULL,
						GenderPreference NVARCHAR(50) NOT NULL,
						IsBookmarked BIT NOT NULL
					);
				");

				// Tự động tạo bảng Bookings trên SQL Server nếu chưa có
				context.Database.ExecuteSqlRaw(@"
					IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Bookings' AND xtype='U')
					CREATE TABLE Bookings (
						Id NVARCHAR(100) PRIMARY KEY,
						RoomId NVARCHAR(100) NOT NULL,
						RoomTitle NVARCHAR(500) NOT NULL,
						RoomAddress NVARCHAR(500) NOT NULL,
						LandlordName NVARCHAR(200) NOT NULL,
						LandlordPhone NVARCHAR(50) NOT NULL,
						UserEmail NVARCHAR(200) NOT NULL,
						UserName NVARCHAR(200) NOT NULL,
						UserPhone NVARCHAR(50) NOT NULL,
						BookingDate NVARCHAR(50) NOT NULL,
						TimeSlot NVARCHAR(100) NOT NULL,
						Note NVARCHAR(MAX) NOT NULL,
						Status NVARCHAR(50) NOT NULL,
						CreatedAt DATETIME2 NOT NULL
					);
				");

				// Tự động tạo bảng StudyPosts trên SQL Server nếu chưa có
				context.Database.ExecuteSqlRaw(@"
					IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='StudyPosts' AND xtype='U')
					CREATE TABLE StudyPosts (
						Id NVARCHAR(100) PRIMARY KEY,
						AuthorName NVARCHAR(200) NOT NULL,
						AuthorEmail NVARCHAR(200) NOT NULL,
						AuthorAvatar NVARCHAR(500) NOT NULL,
						University NVARCHAR(200) NOT NULL,
						Title NVARCHAR(500) NOT NULL,
						Description NVARCHAR(MAX) NOT NULL,
						Subject NVARCHAR(200) NOT NULL,
						Tags NVARCHAR(MAX) NOT NULL,
						MembersCurrent INT NOT NULL,
						MembersNeeded INT NOT NULL,
						CreatedAt DATETIME2 NOT NULL,
						PartnerId INT NOT NULL
					);
				");

				// Tự động tạo bảng ChatMessages trên SQL Server nếu chưa có
				context.Database.ExecuteSqlRaw(@"
					IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='ChatMessages' AND xtype='U')
					CREATE TABLE ChatMessages (
						Id NVARCHAR(100) PRIMARY KEY,
						SenderEmail NVARCHAR(200) NOT NULL,
						ReceiverEmail NVARCHAR(200) NOT NULL,
						SenderName NVARCHAR(200) NOT NULL,
						ReceiverName NVARCHAR(200) NOT NULL,
						Text NVARCHAR(MAX) NOT NULL,
						Timestamp DATETIME2 NOT NULL,
						IsRead BIT NOT NULL
					);
				");

				// Tự động tạo bảng Matches trên SQL Server nếu chưa có
				context.Database.ExecuteSqlRaw(@"
					IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Matches' AND xtype='U')
					CREATE TABLE Matches (
						Id INT IDENTITY(1,1) PRIMARY KEY,
						User1Id INT NOT NULL,
						User2Id INT NOT NULL,
						MatchedAt DATETIME2 NOT NULL
					);
				");

				// Bổ sung các cột mới trong bảng Users nếu chưa có
				context.Database.ExecuteSqlRaw(@"
					IF COL_LENGTH('Users', 'Name') IS NULL ALTER TABLE Users ADD Name NVARCHAR(200) NULL;
					IF COL_LENGTH('Users', 'Bio') IS NULL ALTER TABLE Users ADD Bio NVARCHAR(MAX) NULL;
					IF COL_LENGTH('Users', 'RoomLocation') IS NULL ALTER TABLE Users ADD RoomLocation NVARCHAR(200) NULL;
					IF COL_LENGTH('Users', 'RoomStatus') IS NULL ALTER TABLE Users ADD RoomStatus NVARCHAR(200) NULL;
					IF COL_LENGTH('Users', 'StudyGoal') IS NULL ALTER TABLE Users ADD StudyGoal NVARCHAR(MAX) NULL;
					IF COL_LENGTH('Users', 'CompatibilityScore') IS NULL ALTER TABLE Users ADD CompatibilityScore INT NOT NULL DEFAULT 90;
					IF COL_LENGTH('Users', 'IsOnline') IS NULL ALTER TABLE Users ADD IsOnline BIT NOT NULL DEFAULT 1;
					IF COL_LENGTH('Users', 'AcademicYear') IS NOT NULL ALTER TABLE Users ALTER COLUMN AcademicYear NVARCHAR(MAX) NULL;
					IF COL_LENGTH('Users', 'Faculty') IS NOT NULL ALTER TABLE Users ALTER COLUMN Faculty NVARCHAR(MAX) NULL;
					IF COL_LENGTH('Users', 'Introduction') IS NOT NULL ALTER TABLE Users ALTER COLUMN Introduction NVARCHAR(MAX) NULL;
					IF COL_LENGTH('Users', 'FacebookLink') IS NOT NULL ALTER TABLE Users ALTER COLUMN FacebookLink NVARCHAR(MAX) NULL;
					IF COL_LENGTH('Users', 'GithubLink') IS NOT NULL ALTER TABLE Users ALTER COLUMN GithubLink NVARCHAR(MAX) NULL;
					IF COL_LENGTH('Users', 'SkillsGoodAt') IS NOT NULL ALTER TABLE Users ALTER COLUMN SkillsGoodAt NVARCHAR(MAX) NULL;
					IF COL_LENGTH('Users', 'SkillsToLearn') IS NOT NULL ALTER TABLE Users ALTER COLUMN SkillsToLearn NVARCHAR(MAX) NULL;
					IF COL_LENGTH('Users', 'SleepingTime') IS NOT NULL ALTER TABLE Users ALTER COLUMN SleepingTime NVARCHAR(MAX) NULL;
					IF COL_LENGTH('Users', 'Gender') IS NOT NULL ALTER TABLE Users ALTER COLUMN Gender NVARCHAR(MAX) NULL;
					IF COL_LENGTH('Users', 'AvatarUrl') IS NOT NULL ALTER TABLE Users ALTER COLUMN AvatarUrl NVARCHAR(MAX) NULL;
					IF COL_LENGTH('Users', 'University') IS NOT NULL ALTER TABLE Users ALTER COLUMN University NVARCHAR(MAX) NULL;
					IF COL_LENGTH('Users', 'Major') IS NOT NULL ALTER TABLE Users ALTER COLUMN Major NVARCHAR(MAX) NULL;
					IF COL_LENGTH('Swipes', 'SwipedUserId') IS NULL AND COL_LENGTH('Swipes', 'SwipedId') IS NOT NULL
					BEGIN
						EXEC sp_rename 'Swipes.SwipedId', 'SwipedUserId', 'COLUMN';
					END
				");
			}
			catch (Exception ex)
			{
				Console.WriteLine($"[Cảnh báo khởi tạo bảng SQL Server]: {ex.Message}");
			}
		}

		public static void Seed(AppDbContext context)
		{
			// 1. SEED USERS
			if (!context.Users.Any())
			{
				var sampleUsers = new List<User>
				{
					new User
					{
						Id = 1,
						Email = "nam.nh.k21@ictu.edu.vn",
						Name = "Nguyễn Hoàng Nam",
						PasswordHash = BCrypt.Net.BCrypt.HashPassword("123456"),
						University = "Đại học CNTT & Truyền Thông (ICTU)",
						Major = "Công nghệ thông tin (K21)",
						Faculty = "Công nghệ Thông tin",
						AvatarUrl = "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=500&auto=format&fit=crop&q=80",
						Bio = "Sinh viên năm 4 CNTT. Tính tình hòa đồng, gọn gàng, hay code đêm nhưng đeo tai nghe. Cần tìm bạn ở ghép khu Z115.",
						RentalBudget = 1800000,
						RoomLocation = "Khu vực Z115, gần cổng trường ICTU",
						RoomStatus = "Đã có phòng sẵn (đủ đồ), cần tìm 1 bạn",
						Gender = "Nam",
						IsSmoker = false,
						HasPet = false,
						StudyGoal = "Cần tìm bạn học cùng nhóm đồ án CNTT & ôn thi học kỳ",
						CompatibilityScore = 96,
						IsOnline = true
					},
					new User
					{
						Id = 2,
						Email = "trang.tt.k22@ictu.edu.vn",
						Name = "Trần Thu Trang",
						PasswordHash = BCrypt.Net.BCrypt.HashPassword("123456"),
						University = "Đại học CNTT & Truyền Thông (ICTU)",
						Major = "Kinh tế số & Thương mại điện tử",
						Faculty = "Kinh tế & Quản trị",
						AvatarUrl = "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500&auto=format&fit=crop&q=80",
						Bio = "Thích nấu ăn, sạch sẽ ngăn nắp. Muốn tìm bạn nữ ở ghép khu Tân Thịnh để share tiền phòng và cùng học tiếng Anh.",
						RentalBudget = 1500000,
						RoomLocation = "Đường Tân Thịnh, cách trường 500m",
						RoomStatus = "Đang tìm bạn ở ghép chung phòng",
						Gender = "Nữ",
						IsSmoker = false,
						HasPet = true,
						StudyGoal = "Muốn học nhóm tiếng Anh giao tiếp & luyện TOEIC 650+",
						CompatibilityScore = 92,
						IsOnline = true
					},
					new User
					{
						Id = 3,
						Email = "quan.lv.k21@ictu.edu.vn",
						Name = "Lê Văn Quân",
						PasswordHash = BCrypt.Net.BCrypt.HashPassword("123456"),
						University = "Đại học CNTT & Truyền Thông (ICTU)",
						Major = "Kỹ thuật phần mềm",
						Faculty = "Công nghệ Thông tin",
						AvatarUrl = "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop&q=80",
						Bio = "Đam mê lập trình C++ và giải thuật. Giờ giấc tự do, thích yên tĩnh. Cần tìm phòng hoặc bạn ở ghép khu Z115.",
						RentalBudget = 2000000,
						RoomLocation = "Đường Z115, xã Quyết Thắng",
						RoomStatus = "Đang tìm phòng",
						Gender = "Nam",
						IsSmoker = false,
						HasPet = false,
						StudyGoal = "Cần tìm bạn học chung cấu trúc dữ liệu và thuật toán",
						CompatibilityScore = 88,
						IsOnline = false
					},
					new User
					{
						Id = 4,
						Email = "0000@gmail.com",
						Name = "Tài khoản Sinh viên",
						PasswordHash = BCrypt.Net.BCrypt.HashPassword("123456"),
						University = "Đại học CNTT & Truyền Thông (ICTU)",
						Major = "Công nghệ thông tin",
						Faculty = "Công nghệ Thông tin",
						AvatarUrl = "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80",
						Bio = "Sinh viên ICTU yêu thích công nghệ và tìm bạn ở ghép lý tưởng.",
						RentalBudget = 1700000,
						RoomLocation = "Z115",
						RoomStatus = "Đang tìm bạn ở ghép",
						Gender = "Nam",
						IsSmoker = false,
						HasPet = false,
						StudyGoal = "Luyện Capstone Project",
						CompatibilityScore = 95,
						IsOnline = true
					}
				};

				context.Users.AddRange(sampleUsers);
				context.SaveChanges();
			}

			// 2. SEED ROOMS
			if (!context.Rooms.Any())
			{
				var sampleRooms = new List<RoomListing>
				{
					new RoomListing
					{
						Id = "room_1727670001",
						Title = "Phòng Studio Ban Công Thoáng Mát - Ngõ 18 Đường Z115 (Cách Cổng ICTU 250m)",
						Address = "Số 28, Ngõ 18 Đường Z115, Xã Quyết Thắng, TP. Thái Nguyên",
						UniversityNear = "Đại học CNTT & Truyền Thông (ICTU)",
						Distance = "Cách cổng trường 250m",
						PricePerMonth = 2200000,
						Deposit = 2000000,
						AreaM2 = 26,
						VacantRooms = 2,
						TotalRooms = 8,
						RoomType = "Studio ban công",
						Floor = "Tầng 3",
						MoveInDate = "Vào ở ngay",
						Images = new List<string>
						{
							"https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=900&auto=format&fit=crop&q=80",
							"https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=900&auto=format&fit=crop&q=80",
							"https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=900&auto=format&fit=crop&q=80"
						},
						Amenities = new List<string>
						{
							"Điều hòa Inverter", "Nóng lạnh", "Ban công riêng", "Khóa vân tay", "Máy giặt chung", "Giờ giấc tự do", "Wifi 150Mbps", "Không chung chủ"
						},
						LandlordName = "Cô Lan (Chính chủ)",
						LandlordPhone = "0988 234 567",
						AuthorEmail = "lan.nhatro@gmail.com",
						ElectricityRate = 3500,
						WaterRate = 25000,
						Rating = 4.9,
						ReviewsCount = 18,
						Description = "Phòng khép kín ban công đón gió tự nhiên, đầy đủ tiện nghi điều hòa, bình nóng lạnh, giường đệm cao cấp, bàn học đôi cho sinh viên. Nhà xe có camera an ninh 24/7 và khóa cổng vân tay thông minh.",
						IsAvailable = true,
						GenderPreference = "Tất cả"
					},
					new RoomListing
					{
						Id = "room_1727670002",
						Title = "Căn Hộ Mini Full Đồ Bếp Riêng Hút Mùi - Mặt Đường Tân Thịnh Đối Diện KTX",
						Address = "Số 104 Đường Tân Thịnh, Phường Tân Thịnh, TP. Thái Nguyên",
						UniversityNear = "Đại học CNTT & Truyền Thông (ICTU)",
						Distance = "Cách cổng trường 400m",
						PricePerMonth = 2800000,
						Deposit = 2500000,
						AreaM2 = 32,
						VacantRooms = 1,
						TotalRooms = 12,
						RoomType = "Căn hộ mini",
						Floor = "Tầng 2 (Có thang máy)",
						MoveInDate = "Còn 1 phòng duy nhất",
						Images = new List<string>
						{
							"https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=900&auto=format&fit=crop&q=80",
							"https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=900&auto=format&fit=crop&q=80",
							"https://images.unsplash.com/photo-1484154218962-a197022b5858?w=900&auto=format&fit=crop&q=80"
						},
						Amenities = new List<string>
						{
							"Bếp riêng hút mùi", "Tủ lạnh Inverter", "Điều hòa", "Thang máy", "Bình nóng lạnh", "Bàn ăn & làm việc", "Camera 24/7", "An ninh tuyệt đối"
						},
						LandlordName = "Chú Hùng (Quản lý tòa nhà)",
						LandlordPhone = "0977 890 123",
						AuthorEmail = "hung.apartments@gmail.com",
						ElectricityRate = 3800,
						WaterRate = 28000,
						Rating = 5.0,
						ReviewsCount = 24,
						Description = "Căn hộ mini cao cấp thiết kế hiện đại chuẩn phong cách sống Gen-Z. Bếp riêng tách biệt không lo ám mùi vào phòng ngủ. Thang máy tốc độ cao, có dịch vụ dọn vệ sinh hành lang 3 lần/tuần.",
						IsAvailable = true,
						GenderPreference = "Tất cả"
					},
					new RoomListing
					{
						Id = "room_1727670003",
						Title = "Phòng Khép Kín Gác Lửng Giá Sinh Viên - Đường Z115 Quyết Thắng",
						Address = "Ngõ 42 Đường Z115, Xã Quyết Thắng, TP. Thái Nguyên",
						UniversityNear = "Đại học CNTT & Truyền Thông (ICTU)",
						Distance = "Cách cổng trường 350m",
						PricePerMonth = 1600000,
						Deposit = 1500000,
						AreaM2 = 22,
						VacantRooms = 3,
						TotalRooms = 10,
						RoomType = "Gác lửng",
						Floor = "Tầng 1 & 2",
						MoveInDate = "Vào ở ngay",
						Images = new List<string>
						{
							"https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?w=900&auto=format&fit=crop&q=80",
							"https://images.unsplash.com/photo-1536376072261-38c75010e6c9?w=900&auto=format&fit=crop&q=80"
						},
						Amenities = new List<string>
						{
							"Gác lửng kiên cố", "Vệ sinh khép kín", "Nóng lạnh", "Chỗ để xe free", "Cổng vân tay", "Giờ giấc thoải mái"
						},
						LandlordName = "Bác Minh (Chủ nhà)",
						LandlordPhone = "0912 345 678",
						AuthorEmail = "minh.nhatro@gmail.com",
						ElectricityRate = 3300,
						WaterRate = 20000,
						Rating = 4.8,
						ReviewsCount = 15,
						Description = "Dãy trọ sinh viên yên tĩnh, an ninh tốt, gác lửng ốp gạch sạch sẽ có thể ở được 2 bạn thoải mái. Tiền phòng giá bình dân phù hợp sinh viên năm nhất hoặc sinh viên muốn tiết kiệm chi phí.",
						IsAvailable = true,
						GenderPreference = "Tất cả"
					}
				};

				context.Rooms.AddRange(sampleRooms);
				context.SaveChanges();
			}

			// 3. SEED STUDY POSTS
			if (!context.StudyPosts.Any())
			{
				var samplePosts = new List<StudyPost>
				{
					new StudyPost
					{
						Id = "post_1727670101",
						AuthorName = "Nguyễn Hoàng Nam",
						AuthorEmail = "nam.nh.k21@ictu.edu.vn",
						AuthorAvatar = "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=500",
						University = "Đại học CNTT & Truyền Thông (ICTU)",
						Title = "Tìm 1 bạn cùng làm Đồ Án Chuyên Ngành - Xây dựng Ứng dụng Di Động Flutter",
						Description = "Nhóm mình hiện đã có 2 người, đề tài về ứng dụng quản lý phòng trọ sinh viên. Cần thêm 1 bạn phụ trách giao diện UI/UX Flutter hoặc backend .NET/Dart. Làm việc nghiêm túc, cùng nhau lấy điểm A nhé!",
						Subject = "Đồ Án CNTT",
						Tags = new List<string> { "Flutter", "Dart", ".NET", "Đồ Án K21", "ICTU" },
						MembersCurrent = 2,
						MembersNeeded = 3,
						CreatedAt = DateTime.UtcNow.AddDays(-2),
						PartnerId = 101
					},
					new StudyPost
					{
						Id = "post_1727670102",
						AuthorName = "Trần Thu Trang",
						AuthorEmail = "trang.tt.k22@ictu.edu.vn",
						AuthorAvatar = "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500",
						University = "Đại học CNTT & Truyền Thông (ICTU)",
						Title = "Lập nhóm 3-4 bạn cùng tự học & giải đề TOEIC mục tiêu 650+ chuẩn đầu ra",
						Description = "Nhóm học online buổi tối (20h - 22h) các ngày thứ 3, 5, 7 qua Google Meet. Mỗi buổi cùng giải 1 đề ETS và chữa từ vựng Part 5, 7. Bạn nào có cùng mục tiêu ra trường đúng hạn thì nhắn tin mình nhé!",
						Subject = "Ngoại ngữ & TOEIC",
						Tags = new List<string> { "TOEIC", "Tiếng Anh", "Luyện đề", "Đầu ra chuẩn" },
						MembersCurrent = 2,
						MembersNeeded = 4,
						CreatedAt = DateTime.UtcNow.AddDays(-1),
						PartnerId = 102
					}
				};

				context.StudyPosts.AddRange(samplePosts);
				context.SaveChanges();
			}

			// 4. SEED SAMPLE MESSAGES
			if (!context.ChatMessages.Any())
			{
				var sampleMessages = new List<AppChatMessage>
				{
					new AppChatMessage
					{
						Id = "msg_1790737866841",
						SenderEmail = "nam.nh.k21@ictu.edu.vn",
						ReceiverEmail = "0000@gmail.com",
						SenderName = "Nguyễn Hoàng Nam",
						ReceiverName = "Bạn",
						Text = "Chào bạn! Mình thấy bạn đang tìm phòng khu Z115, bên mình có phòng studio ban công rất đẹp, chiều bạn qua xem thử không?",
						Timestamp = DateTime.UtcNow.AddHours(-2),
						IsRead = false
					},
					new AppChatMessage
					{
						Id = "msg_1790737866857",
						SenderEmail = "0000@gmail.com",
						ReceiverEmail = "nam.nh.k21@ictu.edu.vn",
						SenderName = "Bạn",
						ReceiverName = "Nguyễn Hoàng Nam",
						Text = "Chào Nam! Tuyệt vời quá, tầm 17h30 mình tan học ghé qua xem phòng luôn nhé!",
						Timestamp = DateTime.UtcNow.AddHours(-1),
						IsRead = true
					}
				};

				context.ChatMessages.AddRange(sampleMessages);
				context.SaveChanges();
			}
		}
	}
}
