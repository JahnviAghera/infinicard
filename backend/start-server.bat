@echo off
echo ========================================
echo   INFINICARD BACKEND STARTUP SCRIPT
echo ========================================
echo.

cd /d %~dp0

REM Start Docker containers
if exist docker-compose.yml (
    echo Starting backend containers...
    docker-compose up -d
    if errorlevel 1 (
        echo ERROR: Failed to start containers
        pause
        exit /b 1
    )
    REM Wait for database to be healthy (with pg_isready fallback)
    set /a wait_time=60
    :wait_loop
    set /a wait_time=%wait_time%-1
    if %wait_time% LEQ 0 goto db_ready
    ping -n 2 127.0.0.1 >nul
    docker inspect --format="{{.State.Health.Status}}" infinicard_db | findstr /i "healthy" >nul && goto db_ready
    docker exec infinicard_db pg_isready -U infinicard_user -d infinicard -q >nul 2>nul && goto db_ready
    goto wait_loop
    :db_ready
    echo ========================================
    echo Backend containers are running and database is healthy!
    echo ========================================
    REM Ask user if they want to run the schema SQL file
    set "SCHEMA_FILE=init-db\05-create-professionals.sql"
    if exist "%SCHEMA_FILE%" (
        echo Do you want to run the schema SQL file to (re)create tables and triggers? [Y/N]
        set /p schema_choice=Type Y to run schema, N to skip: 
        if /I "%schema_choice%"=="Y" (
            echo Running schema SQL file: %SCHEMA_FILE% ...
            docker exec -i infinicard_db psql -U infinicard_user -d infinicard < "%SCHEMA_FILE%"
            if errorlevel 1 (
                echo ERROR: Schema SQL execution failed!
                pause
                exit /b 1
            )
            echo Schema SQL execution complete!
        ) else (
            echo Skipping schema SQL. Using current database structure.
        )
    ) else (
        echo No schema SQL file found. Skipping schema step.
    )
    REM Auto-restore latest backup (data-only) if available
    set "BACKUP_FILE=backup\infinicard_autobackup.sql"
    if exist "%BACKUP_FILE%" (
        echo Found backup: %BACKUP_FILE%
        echo Restoring data-only from backup (schema statements will be skipped)...
        REM Filter out schema-changing statements from plain SQL before piping to psql
        findstr /V /I "CREATE TABLE ALTER TABLE DROP TABLE CREATE FUNCTION CREATE EXTENSION CREATE INDEX CREATE SEQUENCE CREATE TRIGGER COMMENT ON EXTENSION" "%BACKUP_FILE%" | docker exec -i infinicard_db psql -U infinicard_user -d infinicard
        if errorlevel 1 (
            echo ERROR: Data-only restore failed!
            pause
            exit /b 1
        )
        echo Data restore complete.
        REM Ensure Adminer stays up after restore
        if exist docker-compose.yml (
            docker-compose up -d adminer >nul 2>nul
        )
    ) else (
        echo No backup file found. Continuing with current database state.
    )
)

echo [1/3] Checking if Node.js is installed...
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Node.js is not installed!
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)
node --version
echo.

echo [2/3] Installing dependencies (if needed)...
if not exist "node_modules\" (
    echo Installing packages...
    call npm install
) else (
    echo Dependencies already installed.
)
echo.

echo [3/3] Starting API server...
echo.
echo ========================================
echo   API will start on http://localhost:3000
echo   Press Ctrl+C to stop the server
echo ========================================
echo.

REM Start Node.js backend server in a new window and continue
echo Launching Node API in a new console...
start "Node Server" cmd /k "cd /d %~dp0src && node server.js"

REM Auto-start ngrok to expose port 3000 (if installed)
echo.
echo Launching ngrok (if available) on port 3000...
where ngrok >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: ngrok not found in PATH. Install from https://ngrok.com/download and ensure ngrok.exe is in PATH.
) else (
    start "ngrok" cmd /k ngrok http 3000
)

pause
