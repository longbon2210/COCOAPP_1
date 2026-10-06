namespace CocoApp.API.DTOs
{
	public class RegisterDto
	{
		public string Email { get; set; } = string.Empty;
		public string Password { get; set; } = string.Empty;
		public string? FullName { get; set; }
		public string? Name { get; set; }
		public string? University { get; set; }
		public string? Faculty { get; set; }
		public string? Major { get; set; }
		public string? AcademicYear { get; set; }
	}
}

