using CocoApp.API.Data;
using CocoApp.API.Hubs;
using CocoApp.API.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;

namespace CocoApp.API.Controllers
{
	[Authorize]
	[Route("api/[controller]")]
	[ApiController]
	public class MessagesController : ControllerBase
	{
		private readonly AppDbContext _context;
		private readonly IHubContext<ChatHub> _hubContext;

		public MessagesController(AppDbContext context, IHubContext<ChatHub> hubContext)
		{
			_context = context;
			_hubContext = hubContext;
		}

		private string? GetCurrentUserEmail()
		{
			var email = User.FindFirst(ClaimTypes.Email)?.Value;
			if (!string.IsNullOrWhiteSpace(email)) return email.Trim().ToLower();

			var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
			if (!string.IsNullOrWhiteSpace(userIdStr) && int.TryParse(userIdStr, out int uid))
			{
				var u = _context.Users.Find(uid);
				if (u?.Email != null) return u.Email.Trim().ToLower();
			}
			return null;
		}

		// GET: api/messages?user1=a@b.com&user2=c@d.com HOẶC api/messages?myEmail=a@b.com
		[HttpGet]
		public IActionResult GetMessages(
			[FromQuery] string? user1,
			[FromQuery] string? user2,
			[FromQuery] string? myEmail)
		{
			var currentEmail = GetCurrentUserEmail();
			var query = _context.ChatMessages.AsQueryable();

			if (!string.IsNullOrWhiteSpace(user1) && !string.IsNullOrWhiteSpace(user2))
			{
				var u1 = user1.Trim().ToLower();
				var u2 = user2.Trim().ToLower();

				// Kiểm tra phân quyền: người dùng chỉ được xem hội thoại có sự tham gia của mình
				if (!string.IsNullOrEmpty(currentEmail) && u1 != currentEmail && u2 != currentEmail)
				{
					return Forbid();
				}

				query = query.Where(m =>
					(m.SenderEmail != null && m.SenderEmail.ToLower() == u1 && m.ReceiverEmail != null && m.ReceiverEmail.ToLower() == u2) ||
					(m.SenderEmail != null && m.SenderEmail.ToLower() == u2 && m.ReceiverEmail != null && m.ReceiverEmail.ToLower() == u1));
			}
			else
			{
				var targetEmail = !string.IsNullOrWhiteSpace(myEmail) ? myEmail.Trim().ToLower() : currentEmail;
				if (!string.IsNullOrEmpty(currentEmail) && !string.IsNullOrEmpty(targetEmail) && targetEmail != currentEmail)
				{
					return Forbid();
				}

				if (!string.IsNullOrEmpty(targetEmail))
				{
					query = query.Where(m => (m.SenderEmail != null && m.SenderEmail.ToLower() == targetEmail) || (m.ReceiverEmail != null && m.ReceiverEmail.ToLower() == targetEmail));
				}
			}

			var messages = query.OrderBy(m => m.Timestamp).ToList();
			return Ok(messages);
		}

		// POST: api/messages
		[HttpPost]
		public async Task<IActionResult> SendMessage([FromBody] AppChatMessage msg)
		{
			if (msg == null) return BadRequest(new { error = "Dữ liệu tin nhắn không hợp lệ" });

			var currentEmail = GetCurrentUserEmail();
			if (!string.IsNullOrEmpty(currentEmail))
			{
				// Khóa chặt người gửi: luôn gán email người gửi từ token JWT xác thực, tránh giả mạo
				msg.SenderEmail = currentEmail;
			}

			if (string.IsNullOrWhiteSpace(msg.Id))
			{
				msg.Id = $"msg_{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}";
			}

			// Kiểm tra trùng lặp tin nhắn (Idempotency deduplication)
			var existing = _context.ChatMessages.FirstOrDefault(m => m.Id == msg.Id);
			if (existing != null)
			{
				return Ok(existing);
			}

			if (msg.Timestamp == default)
			{
				msg.Timestamp = DateTime.UtcNow;
			}

			_context.ChatMessages.Add(msg);
			await _context.SaveChangesAsync();

			// Phát real-time qua SignalR ChatHub
			try
			{
				await _hubContext.Clients.All.SendAsync("ReceiveChatMessage", msg);
			}
			catch (Exception ex)
			{
				Console.WriteLine($"[SignalR Broadcast Error]: {ex.Message}");
			}

			return StatusCode(StatusCodes.Status201Created, msg);
		}
	}
}
