using System.ComponentModel.DataAnnotations;

namespace CocoApp.API.Models
{
	public class StudyPost
	{
		[Key]
		public string Id { get; set; } = string.Empty;
		public string? AuthorName { get; set; }
		public string? AuthorEmail { get; set; }
		public string? AuthorAvatar { get; set; }
		public string? University { get; set; }
		public string? Title { get; set; }
		public string? Description { get; set; }
		public string? Subject { get; set; }
		public List<string> Tags { get; set; } = new();
		public int MembersCurrent { get; set; } = 1;
		public int MembersNeeded { get; set; } = 4;
		public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
		public int PartnerId { get; set; }
	}
}
