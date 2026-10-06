using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace CocoApp.API.DTOs
{
	public class LoginDto
	{
		public string Email { get; set; } = string.Empty;
		public string Password { get; set; } = string.Empty;
	}
}
