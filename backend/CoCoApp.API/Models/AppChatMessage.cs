using System.ComponentModel.DataAnnotations;

namespace CocoApp.API.Models
{
	public class AppChatMessage
	{
		[Key]
		public string Id { get; set; } = string.Empty;
		public string SenderEmail { get; set; } = string.Empty;
		public string ReceiverEmail { get; set; } = string.Empty;
		public string SenderName { get; set; } = string.Empty;
		public string ReceiverName { get; set; } = string.Empty;
		public string Text { get; set; } = string.Empty;
		public DateTime Timestamp { get; set; } = DateTime.UtcNow;
		public bool IsRead { get; set; } = false;
	}
}
