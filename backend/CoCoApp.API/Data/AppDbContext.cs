using System.Text.Json;
using CocoApp.API.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;

namespace CocoApp.API.Data
{
	public class AppDbContext : DbContext
	{
		public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

		public DbSet<User> Users { get; set; }
		public DbSet<Match> Matches { get; set; }
		public DbSet<Swipe> Swipes { get; set; }
		public DbSet<Message> Messages { get; set; }

		// Bảng phòng trọ, đặt lịch, nhóm học tập và tin nhắn app
		public DbSet<RoomListing> Rooms { get; set; }
		public DbSet<RoomBooking> Bookings { get; set; }
		public DbSet<StudyPost> StudyPosts { get; set; }
		public DbSet<AppChatMessage> ChatMessages { get; set; }

		protected override void OnModelCreating(ModelBuilder modelBuilder)
		{
			base.OnModelCreating(modelBuilder);

			var jsonOptions = (JsonSerializerOptions)null!;
			var stringListComparer = new ValueComparer<List<string>>(
				(c1, c2) => c1 != null && c2 != null ? c1.SequenceEqual(c2) : c1 == c2,
				c => c.Aggregate(0, (a, v) => HashCode.Combine(a, v.GetHashCode())),
				c => c.ToList());

			modelBuilder.Entity<RoomListing>()
				.Property(e => e.Images)
				.HasConversion(
					v => JsonSerializer.Serialize(v, jsonOptions),
					v => JsonSerializer.Deserialize<List<string>>(v, jsonOptions) ?? new List<string>()
				)
				.Metadata.SetValueComparer(stringListComparer);

			modelBuilder.Entity<RoomListing>()
				.Property(e => e.Amenities)
				.HasConversion(
					v => JsonSerializer.Serialize(v, jsonOptions),
					v => JsonSerializer.Deserialize<List<string>>(v, jsonOptions) ?? new List<string>()
				)
				.Metadata.SetValueComparer(stringListComparer);

			modelBuilder.Entity<StudyPost>()
				.Property(e => e.Tags)
				.HasConversion(
					v => JsonSerializer.Serialize(v, jsonOptions),
					v => JsonSerializer.Deserialize<List<string>>(v, jsonOptions) ?? new List<string>()
				)
				.Metadata.SetValueComparer(stringListComparer);

			modelBuilder.Entity<User>()
				.Property(e => e.RentalBudget)
				.HasColumnType("decimal(18,2)");
		}
	}
}