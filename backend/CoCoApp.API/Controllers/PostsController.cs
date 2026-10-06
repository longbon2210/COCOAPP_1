using CocoApp.API.Data;
using CocoApp.API.Models;
using Microsoft.AspNetCore.Mvc;

namespace CocoApp.API.Controllers
{
	[Route("api/[controller]")]
	[ApiController]
	public class PostsController : ControllerBase
	{
		private readonly AppDbContext _context;

		public PostsController(AppDbContext context)
		{
			_context = context;
		}

		// GET: api/posts
		[HttpGet]
		public IActionResult GetAllPosts()
		{
			var posts = _context.StudyPosts.OrderByDescending(p => p.CreatedAt).ToList();
			return Ok(posts);
		}

		// GET: api/posts/{id}
		[HttpGet("{id}")]
		public IActionResult GetPostById(string id)
		{
			var post = _context.StudyPosts.Find(id);
			if (post == null) return NotFound(new { message = "Không tìm thấy bài viết" });
			return Ok(post);
		}

		// POST: api/posts
		[HttpPost]
		public IActionResult CreatePost([FromBody] StudyPost post)
		{
			if (string.IsNullOrWhiteSpace(post.Id))
			{
				post.Id = $"post_{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}";
			}

			if (post.CreatedAt == default)
			{
				post.CreatedAt = DateTime.UtcNow;
			}

			_context.StudyPosts.Add(post);
			_context.SaveChanges();

			return StatusCode(StatusCodes.Status201Created, post);
		}

		// DELETE: api/posts?id={id}
		[HttpDelete]
		public IActionResult DeletePostByQuery([FromQuery] string id)
		{
			if (string.IsNullOrEmpty(id)) return BadRequest(new { error = "Thiếu id bài viết" });

			var post = _context.StudyPosts.Find(id);
			if (post == null) return NotFound(new { message = "Không tìm thấy bài viết" });

			_context.StudyPosts.Remove(post);
			_context.SaveChanges();

			return Ok(new { success = true, id });
		}

		// DELETE: api/posts/{id}
		[HttpDelete("{id}")]
		public IActionResult DeletePostByRoute(string id)
		{
			var post = _context.StudyPosts.Find(id);
			if (post == null) return NotFound(new { message = "Không tìm thấy bài viết" });

			_context.StudyPosts.Remove(post);
			_context.SaveChanges();

			return Ok(new { success = true, id });
		}
	}
}
