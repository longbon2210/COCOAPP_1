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
