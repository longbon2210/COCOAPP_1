using CocoApp.API.Data;
using CocoApp.API.DTOs;
using CocoApp.API.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace CocoApp.API.Controllers
{
	[Route("api/[controller]")]
	[ApiController]
	[Authorize] // Bắt buộc phải đăng nhập mới được quẹt
	public class MatchController : ControllerBase
	{
		private readonly AppDbContext _context;

		public MatchController(AppDbContext context)
		{
			_context = context;
		}

		[HttpPost("swipe")]
		public IActionResult Swipe([FromBody] SwipeDto request)
		{
			// 1. Lấy ID của chính mình từ Token
			var swiperId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

			// 2. Kiểm tra các trường hợp không hợp lệ
			if (swiperId == request.SwipedId)
				return BadRequest("Bạn không thể tự quẹt hồ sơ của chính mình!");

			var targetUser = _context.Users.Find(request.SwipedId);
			if (targetUser == null)
				return NotFound("Không tìm thấy hồ sơ của người này!");

			var existingSwipe = _context.Swipes.FirstOrDefault(s => s.SwiperId == swiperId && s.SwipedUserId == request.SwipedId);
			if (existingSwipe != null)
				return BadRequest("Bạn đã thao tác với hồ sơ này rồi!");

			// 3. Bắt đầu xử lý hành động quẹt
			var swipe = new Swipe
			{
				SwiperId = swiperId,
				SwipedUserId = request.SwipedId,
				IsLike = request.IsLike
			};

			string message = "Đã bỏ qua hồ sơ."; // Mặc định nếu quẹt trái

			// Nếu bạn quẹt phải (Thích)
			if (request.IsLike)
			{
				message = "Đã thả tim hồ sơ! Chờ người ấy phản hồi nhé.";

				// KIỂM TRA TƯƠNG HỢP: Tìm xem người kia có từng "Thích" mình không?
				var targetLike = _context.Swipes.FirstOrDefault(s => s.SwiperId == request.SwipedId && s.SwipedUserId == swiperId && s.IsLike);

				if (targetLike != null)
				{
					// Đã tìm thấy! Cả 2 cùng thích nhau -> MATCH!
					swipe.IsMatch = true;
					targetLike.IsMatch = true; // Cập nhật luôn trạng thái của người kia
					message = "CHÚC MỪNG! Bạn và người ấy đã Tương hợp (Match)!";
				}
			}

			// 4. Lưu vào Database
			_context.Swipes.Add(swipe);
			_context.SaveChanges();

			return Ok(new { Message = message, IsMatch = swipe.IsMatch });
		}
		// --- API LẤY DANH SÁCH NHỮNG NGƯỜI ĐÃ MATCH ---
		[HttpGet("my-matches")]
		public IActionResult GetMatches()
		{
			var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
			if (userIdString == null) return Unauthorized();

			var currentUserId = int.Parse(userIdString);

			// 1. Tìm ID của những người đã Match với bạn
			var matchedUserIds = _context.Swipes
				.Where(s => s.SwiperId == currentUserId && s.IsMatch == true)
				.Select(s => s.SwipedUserId)
				.ToList();

			// 2. Lấy thông tin cơ bản của họ để hiển thị lên danh sách chat
			var matchedProfiles = _context.Users
				.Where(u => matchedUserIds.Contains(u.Id))
				.Select(u => new
				{
					Id = u.Id,
					AvatarUrl = u.AvatarUrl,
					Email = u.Email, // Tạm dùng Email làm tên hiển thị
					University = u.University,
					Major = u.Major
				})
				.ToList();

			return Ok(matchedProfiles);
		}
	}
}