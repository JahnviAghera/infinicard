# Quick Fix for 404 Errors on Discover Endpoints

## Problem
The discover endpoints are returning 404 errors because the database tables haven't been created yet.

## Solution

### Option 1: Restart Backend (If using Docker)
If you're using Docker Compose, the easiest fix is to restart the containers:

```bash
cd backend
docker-compose down
docker-compose up -d
```

This will re-run all SQL initialization scripts including the new `05-create-professionals.sql`.

### Option 2: Manual SQL Execution (If Not Using Docker)
If you're running PostgreSQL manually, you need to execute the SQL file:

```bash
# Connect to PostgreSQL
psql -U postgres -d infinicard_db

# Then run the SQL file
\i backend/init-db/05-create-professionals.sql

# Or if in Windows Command Prompt:
psql -U postgres -d infinicard_db -f backend\init-db\05-create-professionals.sql
```

### Option 3: Using Adminer (Web UI)
1. Open Adminer at http://localhost:8080
2. Login with your database credentials
3. Click "SQL command"
4. Copy and paste the contents of `backend/init-db/05-create-professionals.sql`
5. Click "Execute"

### Option 4: Quick Script (Windows)
Create a file `backend/run-migrations.bat`:

```batch
@echo off
echo Running database migrations...
psql -U postgres -d infinicard_db -f init-db\05-create-professionals.sql
echo Done!
pause
```

Then run: `cd backend && run-migrations.bat`

## Verify the Fix

After running any of the above solutions, restart your Node.js server:

```bash
cd backend
npm start
```

Then test the endpoints:

```bash
# Test locations endpoint
curl http://localhost:3000/api/discover/locations ^
  -H "Authorization: Bearer YOUR_TOKEN"

# Test professionals endpoint
curl http://localhost:3000/api/discover/professionals ^
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Check if Tables Exist

To verify the tables were created:

```sql
-- List all tables
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';

-- Check professionals table
SELECT * FROM professionals LIMIT 5;

-- Check connections table
SELECT * FROM connections LIMIT 5;
```

## Common Issues

### Issue: "relation does not exist"
**Solution**: The SQL file hasn't been executed. Follow Option 1, 2, or 3 above.

### Issue: "Cannot connect to database"
**Solution**: Make sure PostgreSQL is running:
```bash
# Check if PostgreSQL is running
docker ps  # If using Docker
# OR
pg_isready  # If installed locally
```

### Issue: "Authentication failed"
**Solution**: Check your database credentials in `.env` file:
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=infinicard_db
DB_USER=postgres
DB_PASSWORD=your_password
```

## Expected Result

After successful setup, you should see:
- 8 sample professionals in the discover screen
- Location filter options: All, Mumbai, Delhi, Bangalore, Pune
- Field filter options: All, Technology, Marketing, Design, Finance
- Ability to send connection requests

## Need More Help?

Check the main documentation:
- `DISCOVER_BACKEND_INTEGRATION.md` - Full integration guide
- `backend/API_DOCUMENTATION.md` - API endpoint documentation
- `backend/README.md` - Backend setup guide
