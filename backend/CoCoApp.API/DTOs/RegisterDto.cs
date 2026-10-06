namespace CocoApp.API.DTOs
{
	public class RegisterDto
	{
		public string Email { get; set; } = string.Empty;
		public string Password { get; set; } = string.Empty;
		public string University { get; set; } = string.Empty; // Phục vụ quản lý hồ sơ FR-05[cite: 1]
		public string Major { get; set; } = string.Empty;      // Phục vụ quản lý hồ sơ FR-05[cite: 1]
	}
}
