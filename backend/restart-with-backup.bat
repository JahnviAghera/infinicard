@echo off
setlocal

REM Backend Restart & DB Restore Utility (Batch)
REM Edit the variables below as needed

set "API_PORT=3000"
set "BACKEND_DIR=%~dp0"
set "BACKUP_FILE=%BACKEND_DIR%backup\infinicard_autobackup.sql"
set "DB_CONTAINER=infinicard_db"
set "DB_USER=infinicard_user"
set "DB_NAME=infinicard"

REM Optional SSH reverse-tunnel config (leave empty to disable)
set "SSH_REMOTE_USER="
set "SSH_REMOTE_HOST="
set "SSH_REMOTE_PORT=8080"
set "SSH_IDENTITY_FILE="
set "SSH_REMOTE_BIND_ALL=false"

echo.
echo ============================================================
echo [1/5] Starting Node.js API server
echo ============================================================
echo Checking for existing Node processes on port %API_PORT%...

for /f "tokens=5" %%A in ('netstat -ano ^| findstr ":%API_PORT% " ^| findstr LISTENING') do (
    echo Killing process %%A using port %API_PORT%...
    taskkill /PID %%A /F >nul 2>&1
)

where node >nul 2>&1
if errorlevel 1 (
    echo WARNING: Node.js not found in PATH.
) else (
    if exist "%BACKEND_DIR%src\server.js" (
        echo Starting Node API in new window...
        start "Node API" cmd /k "cd /d "%BACKEND_DIR%src" && node server.js"
        timeout /t 2 /nobreak >nul
    ) else (
        echo WARNING: server.js not found; skipping API start.
    )
)

echo.
echo ============================================================
echo [2/5] Starting tunnel (SSH / cloudflared / ngrok)
echo ============================================================
REM Try SSH reverse tunnel if configured
where ssh >nul 2>&1
if not "%SSH_REMOTE_HOST%"=="" if not "%SSH_REMOTE_USER%"=="" if errorlevel 0 (
    echo Starting SSH reverse tunnel: %SSH_REMOTE_USER%@%SSH_REMOTE_HOST%:%SSH_REMOTE_PORT% -> localhost:%API_PORT%
    set "IDENTITY="
    if not "%SSH_IDENTITY_FILE%"=="" set "IDENTITY=-i "%SSH_IDENTITY_FILE%" "
    if /i "%SSH_REMOTE_BIND_ALL%"=="true" (
        start "SSH Tunnel" cmd /k "ssh %IDENTITY% -N -R 0.0.0.0:%SSH_REMOTE_PORT%:localhost:%API_PORT% %SSH_REMOTE_USER%@%SSH_REMOTE_HOST% -o ExitOnForwardFailure=yes -o ServerAliveInterval=60"
    ) else (
        start "SSH Tunnel" cmd /k "ssh %IDENTITY% -N -R %SSH_REMOTE_PORT%:localhost:%API_PORT% %SSH_REMOTE_USER%@%SSH_REMOTE_HOST% -o ExitOnForwardFailure=yes -o ServerAliveInterval=60"
    )
    timeout /t 2 /nobreak >nul
) else (
    where cloudflared >nul 2>&1
    if errorlevel 0 (
        echo Starting cloudflared in new window...
        start "cloudflared" cmd /k "cloudflared tunnel --url http://localhost:%API_PORT%"
        timeout /t 2 /nobreak >nul
    ) else (
        where ngrok >nul 2>&1
        if errorlevel 0 (
            echo Starting ngrok in new window...
            start "ngrok" cmd /k "ngrok http %API_PORT%"
            timeout /t 2 /nobreak >nul
        ) else (
            echo WARNING: No tunnel tool found (ssh/cloudflared/ngrok). Install one or configure SSH variables.
        )
    )
)

echo.
echo ============================================================
echo [3/5] Restarting Docker containers
echo ============================================================
where docker >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker not found in PATH. Install Docker Desktop.
    pause
    exit /b 1
)

pushd "%BACKEND_DIR%" >nul 2>&1
echo Bringing down containers...
docker-compose down
echo Starting containers...
docker-compose up -d
if errorlevel 1 (
    echo ERROR: Failed to start containers.
    popd >nul 2>&1
    pause
    exit /b 1
)
echo Docker containers are up.
popd >nul 2>&1

echo.
echo ============================================================
echo [4/5] Waiting for database to become healthy
echo ============================================================
set /a maxWait=60
set /a waited=0

:wait_db
if %waited% geq %maxWait% (
    echo.
    echo ERROR: Database did not become healthy in %maxWait% seconds.
    pause
    exit /b 1
)

REM Check database readiness
docker exec %DB_CONTAINER% pg_isready -U %DB_USER% -d %DB_NAME% >nul 2>&1
if %ERRORLEVEL%==0 (
    echo Database is healthy.
) else (
    set /a waited+=2
    <nul set /p ="Waiting for database... (%waited%/%maxWait% seconds)`r"
    timeout /t 2 /nobreak >nul
    goto wait_db
)

echo.
echo ============================================================
echo [5/5] Restoring data from backup
echo ============================================================
if exist "%BACKUP_FILE%" (
    echo Found backup file: %BACKUP_FILE%
    echo Creating pre-restore auto-backup...
    set "PRE_RESTORE=%BACKEND_DIR%backup\autobackup_before_restore.sql"
    docker exec %DB_CONTAINER% pg_dump -U %DB_USER% -d %DB_NAME% > "%PRE_RESTORE%" 2>nul

    echo Restoring data-only (skipping schema statements)...
    REM Use PowerShell to filter out schema-related statements and pipe into psql
    powershell -NoProfile -Command ^
      "Get-Content -LiteralPath '%BACKUP_FILE%' -Raw | Select-String -NotMatch 'CREATE TABLE|ALTER TABLE|DROP TABLE|CREATE FUNCTION|CREATE EXTENSION|CREATE INDEX|CREATE SEQUENCE|CREATE TRIGGER|COMMENT ON EXTENSION' | Out-String | & docker exec -i %DB_CONTAINER% psql -U %DB_USER% -d %DB_NAME%" 

    if %ERRORLEVEL%==0 (
        echo Data restore complete.
    ) else (
        echo WARNING: Data restore encountered errors, continuing...
    )

    echo Ensuring Adminer is running...
    pushd "%BACKEND_DIR%" >nul 2>&1
    docker-compose up -d adminer >nul 2>&1
    popd >nul 2>&1
) else (
    echo No backup file found at %BACKUP_FILE%. Skipping restore.
)

echo.
echo ============================================================
echo All tasks complete!
echo.
echo Services running:
echo   - Node API:  http://localhost:%API_PORT%
echo   - Tunnel:    Check tunnel window for public URL
echo   - Adminer:   http://localhost:8080
echo   - Database:  Ready and restored
echo ============================================================

pause
endlocal