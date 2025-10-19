@echo off
setlocal
REM =============================================
REM Auto-backup database on shutdown, restore on startup
REM =============================================

REM Set backup file name
set "BACKUP_DIR=backup"
if not exist %BACKUP_DIR% mkdir %BACKUP_DIR%
set "BACKUP_FILE=%BACKUP_DIR%\infinicard_autobackup.sql"

REM --- BACKUP STEP (run before shutdown) ---
if "%1"=="backup" (
    echo Backing up database to %BACKUP_FILE% ...
    docker exec infinicard_db pg_dump -U infinicard_user -d infinicard > "%BACKUP_FILE%"
    if errorlevel 1 (
        echo ERROR: Database backup failed!
        pause
        exit /b 1
    )
    echo Backup complete: %BACKUP_FILE%
    exit /b 0
)

REM --- RESTORE STEP (run before startup) ---
if "%1"=="restore" (
    echo =============================================
    echo Restore database from backup
    echo =============================================
    echo.
    echo Choose restore option:
    echo [1] Restore from last backup (recommended)
    echo [2] Start with empty database
    set /p choice=Enter 1 or 2: 
    if "%choice%"=="1" (
        echo Restoring database from %BACKUP_FILE% ...
        docker exec -i infinicard_db psql -U infinicard_user -d infinicard < "%BACKUP_FILE%"
        if errorlevel 1 (
            echo ERROR: Database restore failed!
            pause
            exit /b 1
        )
        echo Restore complete!
    ) else (
        echo Starting with empty database. No restore performed.
    )
    exit /b 0
)

REM --- USAGE INSTRUCTIONS ---
echo Usage:
echo   auto-backup-restore.bat backup   (run before shutdown)
echo   auto-backup-restore.bat restore  (run before startup)
pause
endlocal
