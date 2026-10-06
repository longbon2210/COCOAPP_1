using CocoApp.API.Data;
using CocoApp.API.Models;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;

namespace CocoApp.API.Hubs
{
	public class ChatHub : Hub
	{
		private readonly AppDbContext _context;

		public ChatHub(AppDbContext context)
		{
			_context = context;
		}

		// Hàm này sẽ được Frontend gọi khi gửi tin theo ID người nhận
		public async Task SendMessage(int receiverId, string content)
		{
			// 1. Trích xuất ID của người gửi từ Token hoặc Claim, mặc định 4 nếu demo
			int senderId = 4;
			var senderIdString = Context.UserIdentifier ?? Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
			if (!string.IsNullOrEmpty(senderIdString) && int.TryParse(senderIdString, out int parsedId))
			{
				senderId = parsedId;
			}

			// 2. Lưu tin nhắn vào bảng Messages
			var message = new Message
			{
				SenderId = senderId,
				ReceiverId = receiverId,
				Content = content,
				SentAt = DateTime.UtcNow
			};

			_context.Messages.Add(message);

			// Đồng bộ lưu luôn vào bảng ChatMessages để Flutter tải lại lịch sử nhất quán
			var senderUser = _context.Users.Find(senderId);
			var receiverUser = _context.Users.Find(receiverId);

			var appMsg = new AppChatMessage
			{
				Id = $"msg_{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}",
				SenderEmail = senderUser?.Email ?? "user@cocoapp.vn",
				ReceiverEmail = receiverUser?.Email ?? "partner@cocoapp.vn",
				SenderName = senderUser?.Name ?? "Sinh viên",
				ReceiverName = receiverUser?.Name ?? "Bạn bè",
				Text = content,
				Timestamp = DateTime.UtcNow,
				IsRead = false
			};
			_context.ChatMessages.Add(appMsg);

			await _context.SaveChangesAsync();

			// 3. Phóng tin nhắn real-time tới thiết bị người nhận và broadcast cho client đang mở phòng chat
			await Clients.User(receiverId.ToString()).SendAsync("ReceiveMessage", senderId, content, message.SentAt);
			await Clients.All.SendAsync("ReceiveChatMessage", appMsg);
		}

		// Hàm gửi tin nhắn qua Email & Text (khớp với cấu trúc ChatMessage trong Flutter)
		public async Task SendChatMessage(string senderEmail, string receiverEmail, string senderName, string receiverName, string text)
		{
			var appMsg = new AppChatMessage
			{
				Id = $"msg_{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}",
				SenderEmail = senderEmail,
				ReceiverEmail = receiverEmail,
				SenderName = senderName,
				ReceiverName = receiverName,
				Text = text,
				Timestamp = DateTime.UtcNow,
				IsRead = false
			};

			_context.ChatMessages.Add(appMsg);
			await _context.SaveChangesAsync();

			// Bắn tín hiệu real-time tới tất cả client đang kết nối
			await Clients.All.SendAsync("ReceiveChatMessage", appMsg);
		}
	}
}