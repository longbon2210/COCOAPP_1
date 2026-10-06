using CocoApp.API.Data;
using CocoApp.API.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace CocoApp.API.Controllers
{
	public class SwipeInputDto
	{
		public int? SwiperId { get; set; }
		public int? SwipedUserId { get; set; }
		public int? SwipedId { get; set; }
		public int? TargetUserId { get; set; }
		public bool IsLike { get; set; }

		public int GetTargetId()
		{
			if (SwipedUserId.HasValue) return SwipedUserId.Value;
			if (SwipedId.HasValue) return SwipedId.Value;
			if (TargetUserId.HasValue) return TargetUserId.Value;
			return 0;
		}
	}

	[Authorize]
	[Route("api/[controller]")]
	[Route("api/swipes")]
	[ApiController]
	public class SwipeController : ControllerBase
	{
		private readonly AppDbContext _context;

		public SwipeController(AppDbContext context)
		{
			_context = context;
		}

		// POST: api/swipe hoặc api/swipes
		[HttpPost]
		public IActionResult Swipe([FromBody] SwipeInputDto request)
		{
			if (request == null)
				return BadRequest(new { error = "Dữ liệu không hợp lệ" });

			int targetId = request.GetTargetId();
			if (targetId <= 0)
				return BadRequest(new { error = "Thiếu ID người được chọn" });

			// Khóa chặt: trích xuất swiperId DUY NHẤT từ JWT Token xác thực, nghiêm cấm giả mạo
			var claimId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
			if (string.IsNullOrEmpty(claimId) || !int.TryParse(claimId, out int swiperId))
			{
				return Unauthorized(new { error = "Yêu cầu đăng nhập hợp lệ để thực hiện quẹt tương hợp." });
			}

			if (swiperId == targetId)
				return BadRequest(new { error = "Không thể tự quẹt chính mình" });

			// Kiểm tra quẹt trước đó
			var existingSwipe = _context.Swipes.FirstOrDefault(s => s.SwiperId == swiperId && s.SwipedUserId == targetId);
			if (existingSwipe != null)
			{
				existingSwipe.IsLike = request.IsLike;
				existingSwipe.CreatedAt = DateTime.UtcNow;

				if (request.IsLike && !existingSwipe.IsMatch)
				{
					var targetLikedMe = _context.Swipes.FirstOrDefault(s => s.SwiperId == targetId && s.SwipedUserId == swiperId && s.IsLike);
					if (targetLikedMe != null)
					{
						existingSwipe.IsMatch = true;
						targetLikedMe.IsMatch = true;
						if (!_context.Matches.Any(m => (m.User1Id == Math.Min(swiperId, targetId) && m.User2Id == Math.Max(swiperId, targetId))))
						{
							_context.Matches.Add(new Match
							{
								User1Id = Math.Min(swiperId, targetId),
								User2Id = Math.Max(swiperId, targetId),
								MatchedAt = DateTime.UtcNow
							});
						}
					}
				}
				_context.SaveChanges();
				return Ok(new { message = existingSwipe.IsMatch ? "Chúc mừng! Hai bạn đã tương hợp (Match)!" : "Cập nhật lượt quẹt thành công!", isMatch = existingSwipe.IsMatch });
			}

			var swipe = new Swipe
			{
				SwiperId = swiperId,
				SwipedUserId = targetId,
				IsLike = request.IsLike,
				CreatedAt = DateTime.UtcNow
			};

			bool isMatch = false;
			string message = request.IsLike ? "Đã thích hồ sơ!" : "Đã bỏ qua hồ sơ.";

			if (request.IsLike)
			{
				// Kiểm tra tương hợp hai chiều
				var targetLikedMe = _context.Swipes.FirstOrDefault(s => s.SwiperId == targetId && s.SwipedUserId == swiperId && s.IsLike);
				if (targetLikedMe != null)
				{
					isMatch = true;
					swipe.IsMatch = true;
					targetLikedMe.IsMatch = true;
					message = "Chúc mừng! Hai bạn đã tương hợp (Match)!";

					// Thêm vào bảng Matches
					_context.Matches.Add(new Match
					{
						User1Id = Math.Min(swiperId, targetId),
						User2Id = Math.Max(swiperId, targetId),
						MatchedAt = DateTime.UtcNow
					});
				}
			}

			_context.Swipes.Add(swipe);
			_context.SaveChanges();

			return Ok(new { message, isMatch });
		}

		// GET: api/swipes/my-matches
		[HttpGet("my-matches")]
		public IActionResult GetMyMatches()
		{
			var claimId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
			if (string.IsNullOrEmpty(claimId) || !int.TryParse(claimId, out int swiperId))
			{
				return Unauthorized(new { error = "Yêu cầu đăng nhập." });
			}
			return GetUserMatchesInternal(swiperId);
		}

		// GET: api/swipes/matches/{userId}
		[HttpGet("matches/{userId}")]
		public IActionResult GetUserMatches(int userId)
		{
			var claimId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
			if (string.IsNullOrEmpty(claimId) || !int.TryParse(claimId, out int currentUserId) || currentUserId != userId)
			{
				return Forbid();
			}
			return GetUserMatchesInternal(userId);
		}

		private IActionResult GetUserMatchesInternal(int userId)
		{
			var matchedUserIds = _context.Swipes
				.Where(s => (s.SwiperId == userId || s.SwipedUserId == userId) && s.IsMatch == true)
				.Select(s => s.SwiperId == userId ? s.SwipedUserId : s.SwiperId)
				.Distinct()
				.ToList();

			var matchedProfiles = _context.Users
				.Where(u => matchedUserIds.Contains(u.Id))
				.ToList();

			return Ok(matchedProfiles);
		}
	}
}