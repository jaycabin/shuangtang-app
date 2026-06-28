@echo off
chcp 65001 >nul
title 双糖后端启动器

echo ================================
echo   双糖 (DoubleSugar) 后端启动
echo ================================
echo.

:: 开放防火墙端口（首次需要管理员权限）
echo [1/4] 配置防火墙...
netsh advfirewall firewall add rule name="双糖 Backend 10080" dir=in protocol=tcp localport=10080 action=allow >nul 2>&1
echo    ✅ 端口已放行

:: 启动 PostgreSQL
echo [2/4] 启动 PostgreSQL...
net start postgresql-x64-18 >nul 2>&1
if %errorlevel% equ 0 (
    echo    ✅ PostgreSQL 已启动
) else (
    echo    ⚠ PostgreSQL 可能已运行
)

ping 127.0.0.1 -n 3 >nul

:: 创建数据库
echo [3/4] 检查数据库...
"C:\Program Files\PostgreSQL\18\bin\psql" -U postgres -c "CREATE DATABASE shuangtang;" >nul 2>&1
"C:\Program Files\PostgreSQL\18\bin\psql" -U postgres -d shuangtang -c "SELECT 1" >nul 2>&1
echo    ✅ 数据库就绪

:: 获取本机IP
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4" ^| findstr /v "169.254"') do set MYIP=%%a
set MYIP=%MYIP: =%

echo.
echo ================================
echo   服务器已就绪！
echo.
echo   🌐 本机地址: http://localhost:10080
echo   📱 手机连接: http://%MYIP%:10080
echo.
echo   ⚠ 手机需要和电脑连同一个 WiFi
echo   或者在 constants.dart 里改成上面这个 IP
echo ================================
echo.

:: 运行数据库迁移
cd /d "%~dp0"
echo [4/4] 运行数据库迁移...
go run ./cmd/migrate up >nul 2>&1
echo    ✅ 迁移完成

:: 启动后端
echo.
echo   正在启动后端服务...
go run ./cmd/server

pause
