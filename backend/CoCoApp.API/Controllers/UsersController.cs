using CocoApp.API.Data;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace CocoApp.API.Controllers
{
	[Route("api/[controller]")]
	[Route("api/user")]
	[ApiController]
	public class UsersController : ControllerBase
	{
		private readonly AppDbContext _context;

		public UsersController(AppDbContext context)
		{
			_context = context;
		}

		// GET: api/users
		[HttpGet]
		public IActionResult GetAllUsers()
		{
			var users = _context.Users.Select(u => new
			{
				id = u.Id,
				email = u.Email,
				name = string.IsNullOrEmpty(u.Name) ? u.Email.Split('@', StringSplitOptions.None)[0] : u.Name,
				university = string.IsNullOrEmpty(u.University) ? "Đại học CNTT & Truyền Thông (ICTU)" : u.University,
				major = string.IsNullOrEmpty(u.Major) ? "Công nghệ thông tin" : u.Major,
				avatarUrl = string.IsNullOrEmpty(u.AvatarUrl)
					? "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500"
					: u.AvatarUrl,
				bio = string.IsNullOrEmpty(u.Bio) ? "Sinh viên năng động, mong muốn tìm bạn ở ghép văn minh." : u.Bio,
				rentalBudget = u.RentalBudget ?? 1800000,
				roomLocation = string.IsNullOrEmpty(u.RoomLocation) ? "Khu Z115, Thái Nguyên" : u.RoomLocation,
				roomStatus = string.IsNullOrEmpty(u.RoomStatus) ? "Đang tìm bạn ở ghép" : u.RoomStatus,
				gender = string.IsNullOrEmpty(u.Gender) ? "Nam" : u.Gender,
				isSmoker = u.IsSmoker,
				hasPet = u.HasPet,
				studyGoal = string.IsNullOrEmpty(u.StudyGoal) ? "Cùng học và làm đồ án tốt nghiệp" : u.StudyGoal,
				studySkills = new List<string> { "Học nhóm", "Thuyết trình", "Tiếng Anh", "Lập trình" },
				lifestyleTags = new List<string> { "Không hút thuốc", "Gọn gàng", "Yên tĩnh học tập" },
				compatibilityScore = u.CompatibilityScore > 0 ? u.CompatibilityScore : 92,
				isOnline = u.IsOnline
			}).ToList();

			return Ok(users);
		}

		// GET: api/users/profile HOẶC api/user/profile
		[HttpGet("profile")]
		public IActionResult GetProfile([FromQuery] string? email)
		{
			var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
			Models.User? user = null;

			if (!string.IsNullOrEmpty(userIdString) && int.TryParse(userIdString, out int userId))
			{
				user = _context.Users.FirstOrDefault(u => u.Id == userId);
			}

			if (user == null && !string.IsNullOrWhiteSpace(email))
			{
				user = _context.Users.FirstOrDefault(u => u.Email.ToLower() == email.Trim().ToLower());
			}

			if (user == null)
			{
				user = _context.Users.FirstOrDefault();
			}

			if (user == null) return NotFound(new { error = "Không tìm thấy hồ sơ người dùng" });

			return Ok(new
			{
				id = user.Id,
				email = user.Email,
				name = string.IsNullOrEmpty(user.Name) ? user.Email.Split('@', StringSplitOptions.None)[0] : user.Name,
				university = user.University,
				faculty = user.Faculty,
				major = user.Major,
				academicYear = user.AcademicYear,
				avatarUrl = user.AvatarUrl,
				introduction = user.Introduction,
				bio = user.Bio,
				facebookLink = user.FacebookLink,
				githubLink = user.GithubLink,
				skillsGoodAt = user.SkillsGoodAt,
				skillsToLearn = user.SkillsToLearn,
				sleepingTime = user.SleepingTime,
				gender = user.Gender,
				isSmoker = user.IsSmoker,
				hasPet = user.HasPet,
				rentalBudget = user.RentalBudget
			});
		}

		// DTO hứng toàn bộ dữ liệu hồ sơ từ Flutter gửi lên
		public class UpdateProfileDto
		{
			public string? Name { get; set; }
			public string? AvatarUrl { get; set; }
			public string? University { get; set; }
			public string? Faculty { get; set; }
			public string? Major { get; set; }
			public string? AcademicYear { get; set; }
			public string? Introduction { get; set; }
			public string? Bio { get; set; }
			public string? FacebookLink { get; set; }
			public string? GithubLink { get; set; }
			public string? SkillsGoodAt { get; set; }
			public string? SkillsToLearn { get; set; }
			public string? SleepingTime { get; set; }
			public string? Gender { get; set; }
			public bool? IsSmoker { get; set; }
			public bool? HasPet { get; set; }
			public decimal? RentalBudget { get; set; }
			public string? Email { get; set; }
		}

		// PUT: api/users/profile HOẶC api/user/profile
		[HttpPut("profile")]
		public IActionResult UpdateProfile([FromBody] UpdateProfileDto request)
		{
			var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
			Models.User? user = null;

			if (!string.IsNullOrEmpty(userIdString) && int.TryParse(userIdString, out int userId))
			{
				user = _context.Users.FirstOrDefault(u => u.Id == userId);
			}

			if (user == null && !string.IsNullOrWhiteSpace(request.Email))
			{
				user = _context.Users.FirstOrDefault(u => u.Email.ToLower() == request.Email.Trim().ToLower());
			}

			if (user == null)
			{
				user = _context.Users.FirstOrDefault();
			}

			if (user == null) return NotFound(new { error = "Người dùng không tồn tại!" });

			if (!string.IsNullOrEmpty(request.Name)) user.Name = request.Name;
			if (!string.IsNullOrEmpty(request.AvatarUrl)) user.AvatarUrl = request.AvatarUrl;
			if (!string.IsNullOrEmpty(request.University)) user.University = request.University;
			if (!string.IsNullOrEmpty(request.Faculty)) user.Faculty = request.Faculty;
			if (!string.IsNullOrEmpty(request.Major)) user.Major = request.Major;
			if (!string.IsNullOrEmpty(request.AcademicYear)) user.AcademicYear = request.AcademicYear;
			if (!string.IsNullOrEmpty(request.Introduction)) user.Introduction = request.Introduction;
			if (!string.IsNullOrEmpty(request.Bio)) user.Bio = request.Bio;
			if (!string.IsNullOrEmpty(request.FacebookLink)) user.FacebookLink = request.FacebookLink;
			if (!string.IsNullOrEmpty(request.GithubLink)) user.GithubLink = request.GithubLink;
			if (!string.IsNullOrEmpty(request.SkillsGoodAt)) user.SkillsGoodAt = request.SkillsGoodAt;
			if (!string.IsNullOrEmpty(request.SkillsToLearn)) user.SkillsToLearn = request.SkillsToLearn;
			if (!string.IsNullOrEmpty(request.SleepingTime)) user.SleepingTime = request.SleepingTime;
			if (!string.IsNullOrEmpty(request.Gender)) user.Gender = request.Gender;
			if (request.IsSmoker.HasValue) user.IsSmoker = request.IsSmoker.Value;
			if (request.HasPet.HasValue) user.HasPet = request.HasPet.Value;
			if (request.RentalBudget.HasValue) user.RentalBudget = request.RentalBudget.Value;

			_context.SaveChanges();

			return Ok(new { message = "Cập nhật hồ sơ thành công!", user });
		}
	}
}