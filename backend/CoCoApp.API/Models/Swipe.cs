namespace CocoApp.API.Models
{
	public class Swipe
	{
		public int Id { get; set; }
		public int SwiperId { get; set; }     // ID của người đang quẹt
		public int SwipedUserId { get; set; } // ID của người bị quẹt (người hiển thị trên thẻ)
		public bool IsLike { get; set; }      // True = Vuốt phải (Thích), False = Vuốt trái (Bỏ qua)
		public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
		public bool IsMatch { get; set; } = false;
	}
}