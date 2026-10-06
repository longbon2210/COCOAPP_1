using CocoApp.API.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace CocoApp.API.Controllers
{
	[Route("api/[controller]")]
	[ApiController]
	[Authorize]
	public class ChatController : ControllerBase
	{
		private readonly AppDbContext _context;

		public ChatController(AppDbContext context)
		{
			_context = context;
		}

		[HttpGet("history/{partnerId}")]
		public IActionResult GetChatHistory(int partnerId)
		{
			var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
			if (userIdString == null) return Unauthorized();

			var myId = int.Parse(userIdString);

			// Lấy toàn bộ tin nhắn giữa "Tôi" và "Người ấy", sắp xếp theo thời gian cũ đến mới
			var messages = _context.Messages
				.Where(m => (m.SenderId == myId && m.ReceiverId == partnerId) ||
							(m.SenderId == partnerId && m.ReceiverId == myId))
				.OrderBy(m => m.SentAt)
				.Select(m => new
				{
					m.Id,
					m.SenderId,
					m.ReceiverId,
					m.Content,
					m.SentAt
				})
				.ToList();

			return Ok(messages);
		}
	}
}