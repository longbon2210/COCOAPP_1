using System.ComponentModel.DataAnnotations;

namespace CocoApp.API.Models
{
	public class RoomBooking
	{
		[Key]
		public string Id { get; set; } = string.Empty;
		public string? RoomId { get; set; }
		public string? RoomTitle { get; set; }
		public string? RoomAddress { get; set; }
		public string? LandlordName { get; set; }
		public string? LandlordPhone { get; set; }
		public string? UserEmail { get; set; }
		public string? UserName { get; set; }
		public string? UserPhone { get; set; }
		public string? BookingDate { get; set; }
		public string? TimeSlot { get; set; }
		public string? Note { get; set; }
		public string? Status { get; set; } = "Đã xác nhận";
		public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
	}
}
