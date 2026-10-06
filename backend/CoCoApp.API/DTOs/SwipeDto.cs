namespace CocoApp.API.DTOs
{
	public class SwipeDto
	{
		public int SwipedId { get; set; } // ID của người mà bạn đang quẹt
		public bool IsLike { get; set; }  // True = Quẹt phải (Thích), False = Quẹt trái (Bỏ qua)
	}
}