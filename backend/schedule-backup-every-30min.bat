@echo off
REM =============================================
REM Manual trigger for scheduled backup (for Task Scheduler)
REM =============================================
cd /d "%~dp0"
auto-backup-restore.bat backup
