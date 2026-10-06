using System.ComponentModel.DataAnnotations;

namespace CocoApp.API.Models
{
	public class RoomBooking
	{
		[Key]
		public string Id { get; set; } = string.Empty;
		public string RoomId { get; set; } = string.Empty;
		public string RoomTitle { get; set; } = string.Empty;
		public string RoomAddress { get; set; } = string.Empty;
		public string LandlordName { get; set; } = string.Empty;
		public string LandlordPhone { get; set; } = string.Empty;
		public string UserEmail { get; set; } = string.Empty;
		public string UserName { get; set; } = string.Empty;
		public string UserPhone { get; set; } = string.Empty;
		public string BookingDate { get; set; } = string.Empty;
		public string TimeSlot { get; set; } = string.Empty;
		public string Note { get; set; } = string.Empty;
		public string Status { get; set; } = "Đã xác nhận";
		public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
	}
}
