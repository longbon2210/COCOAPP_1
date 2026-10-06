@echo off
chcp 65001 >nul
title COCO APP - .NET 10 Web API Backend
echo ======================================================================
echo   🥥 KHỞI CHẠY BACKEND COCO APP (.NET 10 WEB API & SWAGGER)
echo ======================================================================
echo.
echo [1] Dang khoi dong Backend API tai: http://localhost:5000
echo [2] Xem tai lieu Swagger UI tai:   http://localhost:5000/swagger
echo.
start "" "http://localhost:5000/swagger"
dotnet run --project backend/CoCoApp.API/CoCoApp.API.csproj
pause
