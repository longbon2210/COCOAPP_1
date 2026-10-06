using System.ComponentModel.DataAnnotations;

namespace CocoApp.API.Models
{
	public class AppChatMessage
	{
		[Key]
		public string Id { get; set; } = string.Empty;
		public string? SenderEmail { get; set; }
		public string? ReceiverEmail { get; set; }
		public string? SenderName { get; set; }
		public string? ReceiverName { get; set; }
		public string? Text { get; set; }
		public DateTime Timestamp { get; set; } = DateTime.UtcNow;
		public bool IsRead { get; set; } = false;
	}
}
