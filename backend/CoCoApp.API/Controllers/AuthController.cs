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
			// Kiểm tra xem Email đã tồn tại chưa
			if (_context.Users.Any(u => u.Email == request.Email))
			{
				return BadRequest("Email này đã được sử dụng!");
			}

			// Tạo user mới và băm mật khẩu
			var newUser = new User
			{
				Email = request.Email,
				PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
				University = request.University,
				Major = request.Major
			};

			// Lưu vào database
			_context.Users.Add(newUser);
			_context.SaveChanges();

			return Ok("Đăng ký tài khoản thành công!");
		}

		// --- HÀM ĐĂNG NHẬP (FR-02) ---
		[HttpPost("login")]
		public IActionResult Login([FromBody] LoginDto request)
		{
			// 1. Tìm user trong database bằng Email
			var user = _context.Users.FirstOrDefault(u => u.Email == request.Email);

			// 2. Kiểm tra user có tồn tại và Mật khẩu có khớp với mã băm không
			if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
			{
				return BadRequest("Sai email hoặc mật khẩu!");
			}

			// 3. Quy trình tạo thẻ VIP (JWT Token)
			var tokenHandler = new JwtSecurityTokenHandler();
			var key = Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]!);

			var tokenDescriptor = new SecurityTokenDescriptor
			{
				// Nhét ID của người dùng vào thẻ
				Subject = new ClaimsIdentity(new[] { new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()) }),
				// Hạn sử dụng 1 ngày
				Expires = DateTime.UtcNow.AddDays(1),
				// Chữ ký bảo mật
				SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
			};

			var token = tokenHandler.CreateToken(tokenDescriptor);
			var jwtToken = tokenHandler.WriteToken(token);

			// Trả thẻ JWT về cho người dùng
			return Ok(new { Token = jwtToken, Message = "Đăng nhập thành công!" });
		}
	}
}