using CocoApp.API.Data;
using CocoApp.API.Models;
using Microsoft.AspNetCore.Mvc;

namespace CocoApp.API.Controllers
{
	[Route("api/[controller]")]
	[ApiController]
	public class BookingsController : ControllerBase
	{
		private readonly AppDbContext _context;

		public BookingsController(AppDbContext context)
		{
			_context = context;
		}

		// GET: api/bookings hoặc api/bookings?userEmail=xxx
		[HttpGet]
		public IActionResult GetBookings([FromQuery] string? userEmail)
		{
			var query = _context.Bookings.AsQueryable();

			if (!string.IsNullOrWhiteSpace(userEmail))
			{
				var emailLower = userEmail.Trim().ToLower();
				query = query.Where(b => b.UserEmail.ToLower() == emailLower);
			}

			var bookings = query.OrderByDescending(b => b.CreatedAt).ToList();
			return Ok(bookings);
		}

		// POST: api/bookings
		[HttpPost]
		public IActionResult CreateBooking([FromBody] RoomBooking booking)
		{
			if (string.IsNullOrWhiteSpace(booking.Id))
			{
				booking.Id = $"bk_{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}";
			}

			if (string.IsNullOrWhiteSpace(booking.Status))
			{
				booking.Status = "Đã xác nhận";
			}

			booking.CreatedAt = DateTime.UtcNow;

			_context.Bookings.Add(booking);
			_context.SaveChanges();

			return StatusCode(StatusCodes.Status201Created, booking);
		}

		// DELETE: api/bookings?id={id}
		[HttpDelete]
		public IActionResult DeleteBookingByQuery([FromQuery] string id)
		{
			if (string.IsNullOrEmpty(id)) return BadRequest(new { error = "Thiếu id lịch hẹn" });

			var booking = _context.Bookings.Find(id);
			if (booking == null) return NotFound(new { message = "Không tìm thấy lịch hẹn" });

			_context.Bookings.Remove(booking);
			_context.SaveChanges();

			return Ok(new { success = true, id });
		}

		// DELETE: api/bookings/{id}
		[HttpDelete("{id}")]
		public IActionResult DeleteBookingByRoute(string id)
		{
			var booking = _context.Bookings.Find(id);
			if (booking == null) return NotFound(new { message = "Không tìm thấy lịch hẹn" });

			_context.Bookings.Remove(booking);
			_context.SaveChanges();

			return Ok(new { success = true, id });
		}
	}
}
