@echo off
REM start-mailhog.bat (simplified)
REM Starts Docker Desktop (best-effort), brings up MailHog via docker-compose and opens the MailHog UI

echo ---------------------------------------------
echo Infinicard - Start MailHog Dev Helper (simplified)
echo ---------------------------------------------

:: Try to start Docker Desktop (if installed)
if exist "C:\Program Files\Docker\Docker\Docker Desktop.exe" (
  start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
) else if exist "%ProgramFiles%\Docker\Docker\Docker Desktop.exe" (
  start "" "%ProgramFiles%\Docker\Docker\Docker Desktop.exe"
) else (
  echo Docker Desktop not found in Program Files. Ensure Docker is running.
)

echo Waiting 8 seconds for Docker to initialize (if starting)...
timeout /t 8 /nobreak >nul

:: Move to backend folder (script resides in backend)
pushd "%~dp0"

echo Pulling latest images (this may take a while the first time)...
docker-compose pull

echo Starting MailHog service via docker-compose...
docker-compose up -d mailhog
if %ERRORLEVEL% NEQ 0 (
  echo docker-compose failed to start MailHog. Inspect docker logs for details.
  popd
  pause
  exit /b 1
)

echo Waiting a moment for MailHog to initialize...
timeout /t 2 >nul

echo Opening MailHog UI at http://localhost:8025
start http://localhost:8025

echo MailHog should be available. To view running containers, run: docker ps

popd

echo Done.
pause
