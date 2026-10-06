namespace CocoApp.API.Models
{
	public class Match
	{
		public int Id { get; set; }
		public int User1Id { get; set; } // ID người thứ 1
		public int User2Id { get; set; } // ID người thứ 2
		public DateTime MatchedAt { get; set; } = DateTime.UtcNow;
	}
}