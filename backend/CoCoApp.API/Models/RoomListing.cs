using System.ComponentModel.DataAnnotations;

namespace CocoApp.API.Models
{
	public class RoomListing
	{
		[Key]
		public string Id { get; set; } = string.Empty;
		public string? Title { get; set; }
		public string? Address { get; set; }
		public string? UniversityNear { get; set; }
		public string? Distance { get; set; }
		public double PricePerMonth { get; set; }
		public double Deposit { get; set; }
		public double AreaM2 { get; set; }
		public int VacantRooms { get; set; } = 1;
		public int TotalRooms { get; set; } = 1;
		public string? RoomType { get; set; } = "Phòng khép kín";
		public string? Floor { get; set; } = "Tầng 2";
		public string? MoveInDate { get; set; } = "Vào ở ngay";
		public List<string> Images { get; set; } = new();
		public List<string> Amenities { get; set; } = new();
		public string? LandlordName { get; set; }
		public string? LandlordPhone { get; set; }
		public string? AuthorEmail { get; set; }
		public double ElectricityRate { get; set; } = 3500;
		public double WaterRate { get; set; } = 30000;
		public double Rating { get; set; } = 5.0;
		public int ReviewsCount { get; set; } = 1;
		public string? Description { get; set; }
		public bool IsAvailable { get; set; } = true;
		public string? GenderPreference { get; set; } = "Tất cả";
		public bool IsBookmarked { get; set; } = false;
	}
}
