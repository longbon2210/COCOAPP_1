@echo off
chcp 65001 >nul
title COCO APP - Sinh Viên Thái Nguyên & ICTU
echo ======================================================================
echo   🎉 COCO APP - HỆ SINH THÁI THUÊ TRỌ, Ở GHÉP & HỌC TẬP SINH VIÊN ICTU
echo ======================================================================
echo.
echo [1] Đang mở ứng dụng trên trình duyệt: http://localhost:3000
echo [2] Đã tích hợp Server API & Proxy Thông minh - Không bao giờ lỗi CORS!
echo.

:: Mở trình duyệt mặc định
start "" "http://localhost:3000"

:: Khởi chạy server tích hợp
dart run bin/server.dart
pause
