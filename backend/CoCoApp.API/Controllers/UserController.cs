using CocoApp.API.Data;
using CocoApp.API.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace CocoApp.API.Controllers
{
	[Route("api/[controller]")]
	[ApiController]
	[Authorize] // Đặt ổ khóa ở đây: Toàn bộ API trong file này ĐỀU YÊU CẦU PHẢI CÓ TOKEN!
	public class UserController : ControllerBase
	{
		private readonly AppDbContext _context;

		public UserController(AppDbContext context)
		{
			_context = context;
		}

		// --- 1. API XEM HỒ SƠ (GET: api/user/profile) ---
		[HttpGet("profile")]
		public IActionResult GetProfile()
		{
			// Tự động trích xuất ID người dùng từ thẻ Token
			var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
			if (userIdString == null) return Unauthorized();

			var userId = int.Parse(userIdString);
			var user = _context.Users.Find(userId);
			if (user == null) return NotFound("Không tìm thấy dữ liệu người dùng!");

			// Trả về dữ liệu thông qua DTO để giấu PasswordHash
			var profile = new UserProfileDto
			{
				AvatarUrl = user.AvatarUrl,
				University = user.University,
				Faculty = user.Faculty,
				Major = user.Major,
				AcademicYear = user.AcademicYear,
				Introduction = user.Introduction,
				FacebookLink = user.FacebookLink,
				GithubLink = user.GithubLink,
				SkillsGoodAt = user.SkillsGoodAt,
				SkillsToLearn = user.SkillsToLearn,
				SleepingTime = user.SleepingTime,
				Gender = user.Gender,
				IsSmoker = user.IsSmoker,
				HasPet = user.HasPet,
				RentalBudget = user.RentalBudget
			};

			return Ok(profile);
		}

		// --- 2. API CẬP NHẬT HỒ SƠ (PUT: api/user/profile) ---
		[HttpPut("profile")]
		public IActionResult UpdateProfile([FromBody] UserProfileDto request)
		{
			var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
			if (userIdString == null) return Unauthorized();

			var userId = int.Parse(userIdString);
			var user = _context.Users.Find(userId);
			if (user == null) return NotFound("Không tìm thấy dữ liệu người dùng!");

			// Nhận dữ liệu Frontend gửi lên và cập nhật vào Database
			user.AvatarUrl = request.AvatarUrl;
			user.University = request.University;
			user.Faculty = request.Faculty;
			user.Major = request.Major;
			user.AcademicYear = request.AcademicYear;
			user.Introduction = request.Introduction;
			user.FacebookLink = request.FacebookLink;
			user.GithubLink = request.GithubLink;
			user.SkillsGoodAt = request.SkillsGoodAt;
			user.SkillsToLearn = request.SkillsToLearn;
			user.SleepingTime = request.SleepingTime;
			user.Gender = request.Gender;
			user.IsSmoker = request.IsSmoker;
			user.HasPet = request.HasPet;
			user.RentalBudget = request.RentalBudget;

			// Lưu thay đổi xuống SQL Server
			_context.SaveChanges();

			return Ok("Cập nhật hồ sơ cá nhân thành công!");
		}
		// --- 3. API LẤY DANH SÁCH GỢI Ý ĐỂ QUẸT (GET: api/user/feed) ---
		[HttpGet("feed")]
		public IActionResult GetFeed()
		{
			var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
			if (userIdString == null) return Unauthorized();

			var currentUserId = int.Parse(userIdString);

			// 1. Tìm danh sách ID của những người mà bạn ĐÃ TỪNG QUẸT (dù trái hay phải)
			var swipedUserIds = _context.Swipes
				.Where(s => s.SwiperId == currentUserId)
				.Select(s => s.SwipedUserId)
				.ToList();

			// 2. Lấy danh sách người dùng TỪ CHỐI hiển thị bản thân và những người đã quẹt
			var feedUsers = _context.Users
				.Where(u => u.Id != currentUserId && !swipedUserIds.Contains(u.Id))
				.Select(u => new UserProfileDto
				{
					Id = u.Id, // Trả về ID để Frontend dùng
					AvatarUrl = u.AvatarUrl,
					University = u.University,
					Faculty = u.Faculty,
					Major = u.Major,
					AcademicYear = u.AcademicYear,
					Introduction = u.Introduction,
					SkillsGoodAt = u.SkillsGoodAt,
					SkillsToLearn = u.SkillsToLearn,
					// Không cần trả về Link FB/Github ở màn hình quẹt để bảo mật thông tin
				})
				.ToList();

			return Ok(feedUsers);
		}
	}
}