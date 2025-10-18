@echo off
echo ========================================
echo   INFINICARD BACKEND STARTUP SCRIPT
echo ========================================
echo.

cd /d %~dp0

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

call npm start

pause
