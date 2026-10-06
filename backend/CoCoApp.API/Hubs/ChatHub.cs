using CocoApp.API.Data;
using CocoApp.API.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;

namespace CocoApp.API.Hubs
{
	[Authorize] // Bắt buộc phải có thẻ Token mới được kết nối vào trạm
	public class ChatHub : Hub
	{
		private readonly AppDbContext _context;

		public ChatHub(AppDbContext context)
		{
			_context = context;
		}

		// Hàm này sẽ được Frontend (Flutter) gọi khi người dùng bấm nút "Gửi"
		public async Task SendMessage(int receiverId, string content)
		{
			// 1. Trích xuất ID của người gửi từ Token bảo mật
			var senderIdString = Context.UserIdentifier;
			if (senderIdString == null) return;

			var senderId = int.Parse(senderIdString);

			// 2. Lưu tin nhắn vào cơ sở dữ liệu
			var message = new Message
			{
				SenderId = senderId,
				ReceiverId = receiverId,
				Content = content
			};

			_context.Messages.Add(message);
			await _context.SaveChangesAsync();

			// 3. Phóng tin nhắn real-time tới ĐÚNG thiết bị của người nhận
			// "ReceiveMessage" là tên sự kiện mà ứng dụng điện thoại sẽ lắng nghe
			await Clients.User(receiverId.ToString()).SendAsync("ReceiveMessage", senderId, content, message.SentAt);
		}
	}
}