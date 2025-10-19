@echo off
echo ================================================
echo Adding Professionals Schema to Existing Database
echo ================================================
echo.

cd /d "%~dp0"

echo [1/2] Executing SQL migration...
echo.

docker exec -i infinicard_db psql -U infinicard_user -d infinicard < init-db\05-create-professionals.sql

if errorlevel 1 (
    echo.
    echo ERROR: Failed to execute SQL migration
    echo Make sure Docker containers are running: docker-compose up -d
    pause
    exit /b 1
)

echo.
echo [2/2] Migration completed successfully!
echo.

echo ================================================
echo Database Updated!
echo ================================================
echo.
echo New tables added:
echo - professionals (with 8 sample records)
echo - professional_tags
echo - connections
echo.
echo Your existing data is preserved!
echo.
echo You can now test the discover endpoints in your Flutter app.
echo.
echo Press any key to exit...
pause >nul
