using System.Text;
using CocoApp.API.Data;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

// 1. CẤU HÌNH DATABASE: Tự động hỗ trợ cả SQL Server (Somee) hoặc SQLite cục bộ
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
bool isSqlServer = !string.IsNullOrWhiteSpace(connectionString) && 
                   !connectionString.Contains(".db") && 
                   !connectionString.Contains("[YOUR_PASSWORD]");

builder.Services.AddDbContext<AppDbContext>(options =>
{
	if (isSqlServer)
	{
		options.UseSqlServer(connectionString);
	}
	else
	{
		// Cục bộ: Tự động tạo file SQLite cocoapp.db để ứng dụng hoạt động ngay 100% không phụ thuộc internet
		options.UseSqlite("Data Source=cocoapp.db");
	}
});

// 2. CẤU HÌNH CORS CHO PHÉP FLUTTER WEB & MOBILE KẾT NỐI
builder.Services.AddCors(options =>
{
	options.AddPolicy("AllowAll", policy =>
	{
		policy.AllowAnyOrigin()
			  .AllowAnyHeader()
			  .AllowAnyMethod();
	});
});

// 3. CẤU HÌNH JWT AUTHENTICATION
var jwtSecret = builder.Configuration["Jwt:Key"] ?? "MotChuoiKyTuBiMatRatDaiVaKhoDoanChoDuAnCocoApp123!@#";
var key = Encoding.UTF8.GetBytes(jwtSecret);

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
	.AddJwtBearer(options =>
	{
		options.TokenValidationParameters = new TokenValidationParameters
		{
			ValidateIssuer = false,
			ValidateAudience = false,
			ValidateLifetime = true,
			ValidateIssuerSigningKey = true,
			IssuerSigningKey = new SymmetricSecurityKey(key)
		};
	});

builder.Services.AddControllers();
builder.Services.AddSignalR();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// 4. TỰ ĐỘNG KHỞI TẠO BẢNG & SEED DỮ LIỆU BAN ĐẦU
using (var scope = app.Services.CreateScope())
{
	var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
	try
	{
		db.Database.EnsureCreated();
		DataSeeder.Seed(db);
	}
	catch (Exception ex)
	{
		Console.WriteLine($"[Cảnh báo khởi tạo DB]: {ex.Message}");
	}
}

app.UseSwagger();
app.UseSwaggerUI();

app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<CocoApp.API.Hubs.ChatHub>("/chatHub");

app.Run();