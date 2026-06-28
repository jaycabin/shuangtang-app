@echo off
chcp 65001 >nul
title 双糖后端启动器

echo ================================
echo   双糖 (DoubleSugar) 后端启动
echo ================================
echo.

:: 检查 PostgreSQL 服务状态
sc query postgresql-x64-18 >nul 2>&1
if %errorlevel% equ 0 (
    echo [1/4] 启动 PostgreSQL...
    net start postgresql-x64-18 >nul 2>&1
    if %errorlevel% equ 0 (
        echo    ✅ PostgreSQL 已启动
    ) else (
        echo    ⚠  PostgreSQL 启动失败，尝试直接运行...
    )
) else (
    echo    ⚠  PostgreSQL 服务未安装
)

:: 等 3 秒让数据库就绪
ping 127.0.0.1 -n 3 >nul

:: 创建数据库（如果不存在）
echo [2/4] 检查数据库...
"C:\Program Files\PostgreSQL\18\bin\psql" -U postgres -c "CREATE DATABASE shuangtang;" 2>nul
echo    ✅ 数据库就绪

:: 执行数据库迁移
echo [3/4] 执行数据库迁移...
cd /d "%~dp0"
go run ./cmd/migrate up
echo    ✅ 迁移完成

:: 启动后端服务
echo [4/4] 启动后端服务...
echo.
echo    🌐 服务器地址: http://localhost:10080
echo    🏥 健康检查: http://localhost:10080/health
echo.
go run ./cmd/server

pause
