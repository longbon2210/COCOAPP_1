using CocoApp.API.Data;
using CocoApp.API.Models;
using Microsoft.AspNetCore.Mvc;

namespace CocoApp.API.Controllers
{
	[Route("api/[controller]")]
	[ApiController]
	public class MessagesController : ControllerBase
	{
		private readonly AppDbContext _context;

		public MessagesController(AppDbContext context)
		{
			_context = context;
		}

		// GET: api/messages?user1=a@b.com&user2=c@d.com HOẶC api/messages?myEmail=a@b.com
		[HttpGet]
		public IActionResult GetMessages(
			[FromQuery] string? user1,
			[FromQuery] string? user2,
			[FromQuery] string? myEmail)
		{
			var query = _context.ChatMessages.AsQueryable();

			if (!string.IsNullOrWhiteSpace(user1) && !string.IsNullOrWhiteSpace(user2))
			{
				var u1 = user1.Trim().ToLower();
				var u2 = user2.Trim().ToLower();
				query = query.Where(m =>
					(m.SenderEmail.ToLower() == u1 && m.ReceiverEmail.ToLower() == u2) ||
					(m.SenderEmail.ToLower() == u2 && m.ReceiverEmail.ToLower() == u1));
			}
			else if (!string.IsNullOrWhiteSpace(myEmail))
			{
				var me = myEmail.Trim().ToLower();
				query = query.Where(m => m.SenderEmail.ToLower() == me || m.ReceiverEmail.ToLower() == me);
			}

			var messages = query.OrderBy(m => m.Timestamp).ToList();
			return Ok(messages);
		}

		// POST: api/messages
		[HttpPost]
		public IActionResult SendMessage([FromBody] AppChatMessage msg)
		{
			if (string.IsNullOrWhiteSpace(msg.Id))
			{
				msg.Id = $"msg_{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}";
			}

			if (msg.Timestamp == default)
			{
				msg.Timestamp = DateTime.UtcNow;
			}

			_context.ChatMessages.Add(msg);
			_context.SaveChanges();

			return StatusCode(StatusCodes.Status201Created, msg);
		}
	}
}
