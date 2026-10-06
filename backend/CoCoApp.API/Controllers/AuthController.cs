using CocoApp.API.Data;
using CocoApp.API.DTOs;
using CocoApp.API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace CocoApp.API.Controllers
{
	[Route("api/[controller]")]
	[ApiController]
	public class AuthController : ControllerBase
	{
		private readonly AppDbContext _context;
		private readonly IConfiguration _configuration;

		// Constructor nhận cả Database và Configuration
		public AuthController(AppDbContext context, IConfiguration configuration)
		{
			_context = context;
			_configuration = configuration;
		}

		// --- HÀM ĐĂNG KÝ (FR-01) ---
		[HttpPost("register")]
		public IActionResult Register([FromBody] RegisterDto request)
		{
			if (request == null || string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
			{
				return BadRequest("Vui lòng cung cấp đầy đủ email và mật khẩu!");
			}

			// Kiểm tra xem Email đã tồn tại chưa
			if (_context.Users.Any(u => u.Email == request.Email))
			{
				return BadRequest("Email này đã được sử dụng!");
			}

			// Tạo user mới và băm mật khẩu
			var displayName = !string.IsNullOrWhiteSpace(request.FullName) ? request.FullName : (!string.IsNullOrWhiteSpace(request.Name) ? request.Name : request.Email.Split('@')[0]);
			var newUser = new User
			{
				Email = request.Email,
				PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
				Name = displayName,
				University = !string.IsNullOrWhiteSpace(request.University) ? request.University : "Đại học CNTT & Truyền Thông (ICTU)",
				Faculty = !string.IsNullOrWhiteSpace(request.Faculty) ? request.Faculty : "Công nghệ Thông tin",
				Major = !string.IsNullOrWhiteSpace(request.Major) ? request.Major : "Công nghệ thông tin",
				AcademicYear = !string.IsNullOrWhiteSpace(request.AcademicYear) ? request.AcademicYear : "K20",
				AvatarUrl = "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500",
				Bio = "Sinh viên CocoApp năng động, tìm bạn ở ghép và học tập.",
				Introduction = "Xin chào, mình đang tìm bạn ở ghép và học tập!",
				FacebookLink = "",
				GithubLink = "",
				SkillsGoodAt = "Học nhóm, Tiếng Anh, Lập trình",
				SkillsToLearn = "Flutter, C#",
				SleepingTime = "23:00 - 07:00",
				Gender = "Nam",
				RoomLocation = "Khu Z115, Thái Nguyên",
				RoomStatus = "Đang tìm bạn ở ghép",
				StudyGoal = "Cùng học và làm đồ án tốt nghiệp",
				CompatibilityScore = 90,
				IsOnline = true,
				IsSmoker = false,
				HasPet = false,
				RentalBudget = 2000000
			};

			// Lưu vào database
			_context.Users.Add(newUser);
			_context.SaveChanges();

			return Ok(new { message = "Đăng ký tài khoản thành công!", user = newUser });
		}

		// --- HÀM ĐĂNG NHẬP (FR-02) ---
		[HttpPost("login")]
		public IActionResult Login([FromBody] LoginDto request)
		{
			if (request == null || string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
			{
				return BadRequest("Email và mật khẩu không được để trống!");
			}

			// 1. Tìm user trong database bằng Email
			var user = _context.Users.FirstOrDefault(u => u.Email == request.Email);

			// 2. Kiểm tra user có tồn tại và Mật khẩu có khớp với mã băm không (hoặc mật khẩu thuần nếu có)
			bool isPasswordCorrect = false;
			if (user != null && !string.IsNullOrEmpty(user.PasswordHash))
			{
				if (user.PasswordHash == request.Password)
				{
					isPasswordCorrect = true;
				}
				else
				{
					try
					{
						isPasswordCorrect = BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash);
					}
					catch
					{
						isPasswordCorrect = false;
					}
				}
			}

			if (user == null || !isPasswordCorrect)
			{
				return BadRequest("Sai email hoặc mật khẩu!");
			}

			// 3. Quy trình tạo thẻ VIP (JWT Token)
			var tokenHandler = new JwtSecurityTokenHandler();
			var jwtKey = _configuration["Jwt:Key"] ?? "ChuoiBiMatSieuCapVipPro1234567890!@#$";
			var key = Encoding.UTF8.GetBytes(jwtKey);

			var tokenDescriptor = new SecurityTokenDescriptor
			{
				// Nhét ID của người dùng vào thẻ
				Subject = new ClaimsIdentity(new[] { new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()) }),
				// Hạn sử dụng 30 ngày
				Expires = DateTime.UtcNow.AddDays(30),
				// Chữ ký bảo mật
				SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
			};

			var token = tokenHandler.CreateToken(tokenDescriptor);
			var jwtToken = tokenHandler.WriteToken(token);

			// Trả thẻ JWT về cho người dùng
			return Ok(new 
			{ 
				token = jwtToken, 
				user = user, 
				message = "Đăng nhập thành công!" 
			});
		}
	}
}