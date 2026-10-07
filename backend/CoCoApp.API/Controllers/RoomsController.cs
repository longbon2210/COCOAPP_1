using CocoApp.API.Data;
using CocoApp.API.Models;
using Microsoft.AspNetCore.Mvc;

namespace CocoApp.API.Controllers
{
	[Route("api/[controller]")]
	[ApiController]
	public class RoomsController : ControllerBase
	{
		private readonly AppDbContext _context;

		public RoomsController(AppDbContext context)
		{
			_context = context;
		}

		// GET: api/rooms
		[HttpGet]
		public IActionResult GetAllRooms()
		{
			var rooms = _context.Rooms.ToList();
			return Ok(rooms);
		}

		// GET: api/rooms/{id}
		[HttpGet("{id}")]
		public IActionResult GetRoomById(string id)
		{
			var room = _context.Rooms.Find(id);
			if (room == null) return NotFound(new { message = "Không tìm thấy phòng trọ" });
			return Ok(room);
		}

		// POST: api/rooms
		[HttpPost]
		public IActionResult CreateRoom([FromBody] RoomListing room)
		{
			if (string.IsNullOrWhiteSpace(room.Id))
			{
				room.Id = $"room_{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}";
			}

			room.Title ??= "Phòng trọ sinh viên tiện nghi";
			room.Address ??= "Đường Z115, Thái Nguyên";
			room.UniversityNear ??= "ICTU";
			room.Distance ??= "Cách trường 500m";
			room.RoomType ??= "Phòng khép kín";
			room.Floor ??= "Tầng 2";
			room.MoveInDate ??= "Vào ở ngay";
			room.LandlordName ??= "Chủ trọ";
			room.LandlordPhone ??= "0988123456";
			room.AuthorEmail ??= "sinhvien@ictu.edu.vn";
			room.Description ??= "Phòng trọ sinh viên tiện nghi, an ninh tốt.";
			room.GenderPreference ??= "Tất cả";
			room.Images ??= new List<string> { "https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=800" };
			room.Amenities ??= new List<string> { "Điều hòa", "Nóng lạnh", "Wifi" };

			_context.Rooms.Add(room);
			_context.SaveChanges();

			return StatusCode(StatusCodes.Status201Created, room);
		}

		// DELETE: api/rooms?id={id}
		[HttpDelete]
		public IActionResult DeleteRoomByQuery([FromQuery] string id)
		{
			if (string.IsNullOrEmpty(id)) return BadRequest(new { error = "Thiếu id phòng trọ" });

			var room = _context.Rooms.Find(id);
			if (room == null) return NotFound(new { message = "Không tìm thấy phòng trọ" });

			_context.Rooms.Remove(room);
			_context.SaveChanges();

			return Ok(new { success = true, id });
		}

		// DELETE: api/rooms/{id}
		[HttpDelete("{id}")]
		public IActionResult DeleteRoomByRoute(string id)
		{
			var room = _context.Rooms.Find(id);
			if (room == null) return NotFound(new { message = "Không tìm thấy phòng trọ" });

			_context.Rooms.Remove(room);
			_context.SaveChanges();

			return Ok(new { success = true, id });
		}
	}
}
