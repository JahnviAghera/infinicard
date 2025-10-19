# ======================================================
# Backend Restart & DB Restore Utility (PowerShell)
# ======================================================

$ErrorActionPreference = "Continue"
$API_PORT = 3000
$BACKEND_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$BACKUP_FILE = Join-Path $BACKEND_DIR "backup\infinicard_autobackup.sql"
$DB_CONTAINER = "infinicard_db"
$DB_USER = "infinicard_user"
$DB_NAME = "infinicard"

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "[1/5 Starting Node.js API server]" -ForegroundColor Cyan
Write-Host "============================================================`n" -ForegroundColor Cyan

# Check and kill existing processes on port 3000
Write-Host "Checking for existing Node processes on port $API_PORT..."
$processes = Get-NetTCPConnection -LocalPort $API_PORT -State Listen -ErrorAction SilentlyContinue
if ($processes) {
    foreach ($proc in $processes) {
        $processId = $proc.OwningProcess
        Write-Host "Killing process $processId using port $API_PORT..." -ForegroundColor Yellow
        Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
    }
}

# Start Node.js server
$nodeExists = Get-Command node -ErrorAction SilentlyContinue
if ($nodeExists) {
    $serverPath = Join-Path $BACKEND_DIR "src"
    if (Test-Path (Join-Path $serverPath "server.js")) {
        Start-Process cmd -ArgumentList "/k", "cd /d `"$serverPath`" && node server.js"
        Write-Host "Node API started in new window." -ForegroundColor Green
        Start-Sleep -Seconds 2
    } else {
        Write-Host "WARNING: server.js not found; skipping API start." -ForegroundColor Yellow
    }
} else {
    Write-Host "WARNING: Node.js not found in PATH." -ForegroundColor Yellow
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "[2/5 Starting ngrok tunnel]" -ForegroundColor Cyan
Write-Host "============================================================`n" -ForegroundColor Cyan

$ngrokExists = Get-Command ngrok -ErrorAction SilentlyContinue
if ($ngrokExists) {
    Start-Process cmd -ArgumentList "/k", "ngrok http $API_PORT"
    Write-Host "ngrok started in new window." -ForegroundColor Green
    Start-Sleep -Seconds 2
} else {
    Write-Host "WARNING: ngrok not found in PATH." -ForegroundColor Yellow
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "[3/5 Restarting Docker containers]" -ForegroundColor Cyan
Write-Host "============================================================`n" -ForegroundColor Cyan

$dockerExists = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerExists) {
    Write-Host "ERROR: Docker not found in PATH. Install Docker Desktop." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Push-Location $BACKEND_DIR
docker-compose down
Write-Host ""
docker-compose up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to start containers." -ForegroundColor Red
    Pop-Location
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "Docker containers are up." -ForegroundColor Green
Pop-Location

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "[4/5 Waiting for database to become healthy]" -ForegroundColor Cyan
Write-Host "============================================================`n" -ForegroundColor Cyan

$maxWait = 60
$waited = 0
$healthy = $false

while ($waited -lt $maxWait) {
    $waited += 2
    Start-Sleep -Seconds 2
    
    # Check if database is ready
    $result = docker exec $DB_CONTAINER pg_isready -U $DB_USER -d $DB_NAME 2>$null
    if ($LASTEXITCODE -eq 0) {
        $healthy = $true
        break
    }
    
    Write-Host "Waiting for database... ($waited/$maxWait seconds)" -NoNewline
    Write-Host "`r" -NoNewline
}

if (-not $healthy) {
    Write-Host "`nERROR: Database did not become healthy in $maxWait seconds." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "`nDatabase is healthy." -ForegroundColor Green

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "[5/5 Restoring data from backup]" -ForegroundColor Cyan
Write-Host "============================================================`n" -ForegroundColor Cyan

if (Test-Path $BACKUP_FILE) {
    Write-Host "Found backup file: $BACKUP_FILE" -ForegroundColor Green
    
    Write-Host "Creating pre-restore auto-backup..."
    $preRestoreBackup = Join-Path $BACKEND_DIR "backup\autobackup_before_restore.sql"
    docker exec $DB_CONTAINER pg_dump -U $DB_USER -d $DB_NAME | Out-File -FilePath $preRestoreBackup -Encoding UTF8 -ErrorAction SilentlyContinue
    
    Write-Host "Restoring data-only (skipping schema statements)..."
    $excludePatterns = @(
        "CREATE TABLE",
        "ALTER TABLE",
        "DROP TABLE",
        "CREATE FUNCTION",
        "CREATE EXTENSION",
        "CREATE INDEX",
        "CREATE SEQUENCE",
        "CREATE TRIGGER",
        "COMMENT ON EXTENSION"
    )
    
    Get-Content $BACKUP_FILE | 
        Select-String -NotMatch -Pattern ($excludePatterns -join "|") | 
        docker exec -i $DB_CONTAINER psql -U $DB_USER -d $DB_NAME 2>$null | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Data restore complete." -ForegroundColor Green
    } else {
        Write-Host "WARNING: Data restore encountered errors, continuing..." -ForegroundColor Yellow
    }
    
    Write-Host "Ensuring Adminer is running..."
    Push-Location $BACKEND_DIR
    docker-compose up -d adminer 2>$null | Out-Null
    Pop-Location
} else {
    Write-Host "No backup file found at $BACKUP_FILE. Skipping restore." -ForegroundColor Yellow
}

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "All tasks complete!" -ForegroundColor Green
Write-Host "`nServices running:" -ForegroundColor White
Write-Host "  - Node API:  http://localhost:$API_PORT" -ForegroundColor Cyan
Write-Host "  - ngrok:     Check ngrok window for public URL" -ForegroundColor Cyan
Write-Host "  - Adminer:   http://localhost:8080" -ForegroundColor Cyan
Write-Host "  - Database:  Ready and restored" -ForegroundColor Cyan
Write-Host "============================================================`n" -ForegroundColor Green

Read-Host "Press Enter to close"
