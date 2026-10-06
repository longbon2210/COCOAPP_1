using System.ComponentModel.DataAnnotations;

namespace CocoApp.API.Models
{
	public class StudyPost
	{
		[Key]
		public string Id { get; set; } = string.Empty;
		public string AuthorName { get; set; } = string.Empty;
		public string AuthorEmail { get; set; } = string.Empty;
		public string AuthorAvatar { get; set; } = string.Empty;
		public string University { get; set; } = string.Empty;
		public string Title { get; set; } = string.Empty;
		public string Description { get; set; } = string.Empty;
		public string Subject { get; set; } = string.Empty;
		public List<string> Tags { get; set; } = new();
		public int MembersCurrent { get; set; } = 1;
		public int MembersNeeded { get; set; } = 4;
		public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
		public int PartnerId { get; set; }
	}
}
