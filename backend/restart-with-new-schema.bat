@echo off
echo ================================================
echo Restarting Backend with New Database Schema
echo ================================================
echo.

cd /d "%~dp0"

echo [1/4] Stopping Docker containers...
docker-compose down
if errorlevel 1 (
    echo ERROR: Failed to stop containers
    pause
    exit /b 1
)
echo Done!
echo.

echo [2/4] Removing old database volume...
docker volume rm backend_postgres_data 2>nul
echo Done!
echo.

echo [3/4] Starting Docker containers with fresh database...
docker-compose up -d
if errorlevel 1 (
    echo ERROR: Failed to start containers
    pause
    exit /b 1
)
echo Done!
echo.

echo [4/4] Waiting for database to initialize (15 seconds)...
timeout /t 15 /nobreak >nul
echo Done!
echo.

echo ================================================
echo Backend restarted successfully!
echo ================================================
echo.
echo Database will be initialized with:
echo - All original tables (users, business_cards, etc.)
echo - New professionals table with 8 sample professionals
echo - New connections table for connection requests
echo - New professional_tags table
echo.
echo You can now:
echo 1. Access Adminer at http://localhost:8080
echo 2. Test discover endpoints in your Flutter app
echo.
echo Press any key to exit...
pause >nul
