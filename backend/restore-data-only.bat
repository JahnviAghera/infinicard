@echo off
setlocal
REM =============================================
REM Restore only data from backup, skip schema creation
REM =============================================

REM Set backup file name
set "BACKUP_FILE=backup\infinicard_autobackup.sql"

REM Check if backup file exists
if not exist "%BACKUP_FILE%" (
    echo ERROR: Backup file not found: %BACKUP_FILE%
    pause
    exit /b 1
)

REM Restore only data (no schema)
REM This uses pg_restore with --data-only if backup is in custom format
REM If backup is plain SQL, filter out CREATE/ALTER/DROP statements
REM For plain SQL, use findstr to exclude schema lines

echo Restoring only data from %BACKUP_FILE% ...
REM If backup is plain SQL, filter out schema lines and pipe to psql
findstr /V /I "CREATE TABLE ALTER TABLE DROP TABLE CREATE FUNCTION CREATE EXTENSION CREATE INDEX CREATE SEQUENCE CREATE TRIGGER COMMENT ON EXTENSION" "%BACKUP_FILE%" | docker exec -i infinicard_db psql -U infinicard_user -d infinicard
if errorlevel 1 (
    echo ERROR: Data restore failed!
    pause
    exit /b 1
)
echo Data restore complete!

REM Restart Adminer container
if exist docker-compose.yml (
    echo Restarting Adminer container...
    docker-compose up -d adminer
    echo Adminer should now be available at http://localhost:8080
)

pause
endlocal
