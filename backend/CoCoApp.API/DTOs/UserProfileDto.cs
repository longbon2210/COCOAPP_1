namespace CocoApp.API.DTOs
{
	public class UserProfileDto
	{
		public int Id { get; set; } // THÊM DÒNG NÀY (Để Frontend biết ID của hồ sơ)
		public string AvatarUrl { get; set; } = string.Empty;
		public string University { get; set; } = string.Empty;
		public string Faculty { get; set; } = string.Empty;
		public string Major { get; set; } = string.Empty;
		public string AcademicYear { get; set; } = string.Empty;
		public string Introduction { get; set; } = string.Empty;
		public string FacebookLink { get; set; } = string.Empty;
		public string GithubLink { get; set; } = string.Empty;
		public string SkillsGoodAt { get; set; } = string.Empty;
		public string SkillsToLearn { get; set; } = string.Empty;
		public string SleepingTime { get; set; } = string.Empty;
		public string Gender { get; set; } = string.Empty;
		public bool IsSmoker { get; set; }
		public bool HasPet { get; set; }
		public decimal? RentalBudget { get; set; }
	}
}