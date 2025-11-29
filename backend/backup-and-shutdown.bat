@echo off
setlocal
REM =============================================
REM Backup database before shutting down Docker
REM =============================================

REM Set backup file name with timestamp
set "BACKUP_DIR=backup"
if not exist %BACKUP_DIR% mkdir %BACKUP_DIR%
set "BACKUP_FILE=%BACKUP_DIR%\infinicard_backup_%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%_%TIME:~0,2%-%TIME:~3,2%-%TIME:~6,2%.sql"
set "BACKUP_FILE=%BACKUP_FILE: =%"

REM Run backup using pg_dump inside the Docker container
REM Note: pg_dump must be available in the container
REM If you get 'pg_dump: command not found', use: docker exec infinicard_db apt-get update && docker exec infinicard_db apt-get install -y postgresql-client

echo Backing up database to %BACKUP_FILE% ...
docker exec infinicard_db pg_dump -U infinicard_user -d infinicard > "%BACKUP_FILE%"
if errorlevel 1 (
    echo ERROR: Database backup failed!
    pause
    exit /b 1
)
echo Backup complete: %BACKUP_FILE%

REM Now shut down Docker containers
docker-compose down

echo Docker containers stopped.
pause
endlocal
