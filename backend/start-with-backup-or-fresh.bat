@echo off
setlocal
REM =============================================
REM Start backend database: restore from backup or start fresh
REM =============================================

REM Ensure Docker is running
for /f "tokens=*" %%i in ('docker ps -q') do set docker_running=1
if not defined docker_running (
    echo ERROR: Docker is not running. Please start Docker Desktop first.
    pause
    exit /b 1
)

REM Start containers
echo Starting backend containers...
docker-compose up -d
if errorlevel 1 (
    echo ERROR: Failed to start containers
    pause
    exit /b 1
)

REM Wait for database to be ready
set /a wait_time=15
:wait_loop
set /a wait_time=%wait_time%-1
if %wait_time% LEQ 0 goto db_ready
ping -n 2 127.0.0.1 >nul
REM Check if container is healthy
docker inspect --format="{{.State.Health.Status}}" infinicard_db | findstr /i "healthy" >nul && goto db_ready
goto wait_loop
:db_ready

REM Prompt for restore or fresh start
set "BACKUP_FILE=backup\infinicard_autobackup.sql"
echo =============================================
echo Choose database startup option:
echo [1] Restore from last backup (recommended)
echo [2] Start with empty database
set /p choice=Enter 1 or 2: 
if "%choice%"=="1" (
    if exist "%BACKUP_FILE%" (
        echo Restoring database from %BACKUP_FILE% ...
        docker exec -i infinicard_db psql -U infinicard_user -d infinicard < "%BACKUP_FILE%"
        if errorlevel 1 (
            echo ERROR: Database restore failed!
            pause
            exit /b 1
        )
        echo Restore complete!
    ) else (
        echo ERROR: Backup file not found: %BACKUP_FILE%
        pause
        exit /b 1
    )
) else (
    echo Starting with empty database. No restore performed.
)

REM Start Node.js backend (optional)
REM Uncomment the next line if you want to auto-start Node.js
REM start cmd /k "cd /d %~dp0src && npm start"

echo =============================================
echo Backend startup complete!
echo =============================================
pause
endlocal
