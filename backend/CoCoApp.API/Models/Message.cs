namespace CocoApp.API.Models
{
	public class Message
	{
		public int Id { get; set; }

		// ID của người gửi
		public int SenderId { get; set; }

		// ID của người nhận
		public int ReceiverId { get; set; }

		// Nội dung tin nhắn
		public string Content { get; set; } = string.Empty;

		// Thời gian gửi (mặc định lấy giờ chuẩn quốc tế UTC)
		public DateTime SentAt { get; set; } = DateTime.UtcNow;
	}
}