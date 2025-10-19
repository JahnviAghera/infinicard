@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Backend Restart & DB Restore Utility

REM ======================================================
REM CONFIGURATION
REM ======================================================
set "API_PORT=3000"
set "NODE_ENTRY=src\server.js"
set "BACKUP_DIR=backup"
set "BACKUP_FILE=%BACKUP_DIR%\infinicard_autobackup.sql"
set "DB_CONTAINER=infinicard_db"
set "DB_USER=infinicard_user"
set "DB_NAME=infinicard"
set "WAIT_TIMEOUT=60"

REM ======================================================
REM COLORS (Disabled for compatibility)
REM ======================================================
set "COLOR_INFO="
set "COLOR_WARN="
set "COLOR_ERROR="
set "COLOR_OK="
set "COLOR_RESET="

REM ======================================================
REM FUNCTION: section header
REM ======================================================
:section
echo.
echo ============================================================
echo [%~1]
echo ============================================================
exit /b

REM ======================================================
REM STEP 1: Start Node.js server
REM ======================================================
call :section "1/6 Starting Node.js API server (early start)"

echo Checking for existing Node processes on port %API_PORT%...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":%API_PORT%" ^| findstr "LISTENING"') do (
    echo %COLOR_WARN%Killing process %%a using port %API_PORT%...%COLOR_RESET%
    taskkill /F /PID %%a >nul 2>nul
)

where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo %COLOR_WARN%WARNING: Node.js not found in PATH. Install from https://nodejs.org/%COLOR_RESET%
) else (
    if exist "%~dp0%NODE_ENTRY%" (
        pushd "%~dp0src"
        start "Node Server" cmd /k node server.js
        popd
        echo %COLOR_OK%Node API started in new window.%COLOR_RESET%
    ) else (
        echo %COLOR_WARN%WARNING: %NODE_ENTRY% not found; skipping API start.%COLOR_RESET%
    )
)

REM ======================================================
REM STEP 2: Start ngrok tunnel
REM ======================================================
call :section "2/6 Starting ngrok tunnel on port %API_PORT%"

where ngrok >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo %COLOR_WARN%WARNING: ngrok not found in PATH. Install from https://ngrok.com/download%COLOR_RESET%
) else (
    start "ngrok" cmd /k ngrok http %API_PORT%
    echo %COLOR_OK%ngrok started in new window.%COLOR_RESET%
)

REM ======================================================
REM STEP 3: Stop Docker containers
REM ======================================================
call :section "3/6 Stopping Docker containers (if running)"

where docker >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo %COLOR_ERROR%ERROR: Docker not found in PATH. Install Docker Desktop.%COLOR_RESET%
    pause
    exit /b 1
)

docker-compose down
echo.

REM ======================================================
REM STEP 4: Start Docker containers
REM ======================================================
call :section "4/6 Starting Docker containers"

docker-compose up -d
if errorlevel 1 (
    echo %COLOR_ERROR%ERROR: Failed to start containers.%COLOR_RESET%
    pause
    exit /b 1
)
echo %COLOR_OK%Docker containers are up.%COLOR_RESET%

REM ======================================================
REM STEP 5: Wait for DB to become healthy
REM ======================================================
call :section "5/6 Waiting for database to become healthy"

set /a count=0

:wait_loop
set /a count+=1
if !count! GTR %WAIT_TIMEOUT% (
    echo %COLOR_ERROR%Database did not become healthy in %WAIT_TIMEOUT%s.%COLOR_RESET%
    pause
    exit /b 1
)

docker inspect --format="{{.State.Health.Status}}" %DB_CONTAINER% 2>nul | findstr /i "healthy" >nul && goto db_ready
docker exec %DB_CONTAINER% pg_isready -U %DB_USER% -d %DB_NAME% -q >nul 2>nul && goto db_ready

ping -n 2 127.0.0.1 >nul
goto wait_loop

:db_ready
echo %COLOR_OK%Database is healthy.%COLOR_RESET%

REM ======================================================
REM STEP 6: Restore from backup
REM ======================================================
call :section "6/6 Restoring data from backup (if available)"

if exist "%BACKUP_FILE%" (
    echo %COLOR_OK%Found backup file: %BACKUP_FILE%%COLOR_RESET%

    echo Creating pre-restore auto-backup...
    docker exec %DB_CONTAINER% pg_dump -U %DB_USER% -d %DB_NAME% > "%BACKUP_DIR%\autobackup_before_restore.sql" 2>nul

    echo Restoring data-only (skipping schema statements)...
    type "%BACKUP_FILE%" | findstr /V /I /C:"CREATE TABLE" /C:"ALTER TABLE" /C:"DROP TABLE" /C:"CREATE FUNCTION" /C:"CREATE EXTENSION" /C:"CREATE INDEX" /C:"CREATE SEQUENCE" /C:"CREATE TRIGGER" /C:"COMMENT ON EXTENSION" | docker exec -i %DB_CONTAINER% psql -U %DB_USER% -d %DB_NAME%

    if errorlevel 1 (
        echo %COLOR_WARN%WARNING: Data restore encountered errors, continuing...%COLOR_RESET%
    ) else (
        echo %COLOR_OK%Data restore complete.%COLOR_RESET%
    )

    echo Ensuring Adminer is running...
    docker-compose up -d adminer >nul 2>nul
) else (
    echo %COLOR_WARN%No backup file found at %BACKUP_FILE%. Skipping restore.%COLOR_RESET%
)

REM ======================================================
REM FINISH
REM ======================================================
echo.
echo ============================================================
echo %COLOR_OK%All tasks complete!%COLOR_RESET%
echo.
echo - Node API running at: %COLOR_INFO%http://localhost:%API_PORT%%COLOR_RESET%
echo - ngrok tunnel active (if installed)
echo - Database and containers ready
echo ============================================================
echo.
echo Press any key to close...
pause >nul

endlocal
exit /b
