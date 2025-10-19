# 🚀 Fix 404 Errors - Quick Start Guide

## The Problem
You're seeing 404 errors because the database tables for the discover feature don't exist yet:
```
GET /api/discover/locations 404
GET /api/discover/professionals? 404
GET /api/discover/fields 404
```

## ✅ Quick Solution (Choose One)

### Option A: Add Schema to Existing Database (Recommended - Preserves Your Data)

Run this in Command Prompt:
```bash
cd backend
add-professionals-schema.bat
```

This will:
- ✅ Add the new professionals, connections, and tags tables
- ✅ Keep all your existing business cards
- ✅ Insert 8 sample professionals for testing

### Option B: Fresh Start (Rebuilds Everything)

Run this in Command Prompt:
```bash
cd backend
restart-with-new-schema.bat
```

This will:
- 🔄 Delete the database volume
- 🔄 Recreate all tables from scratch
- ⚠️ **Warning**: You'll lose existing business cards

### Option C: Manual Docker Commands

```bash
cd backend

# Stop containers
docker-compose down

# Remove old volume (optional - only if you want fresh start)
docker volume rm backend_postgres_data

# Start containers
docker-compose up -d

# Wait 15 seconds for database to initialize
timeout /t 15

# Or manually run the SQL
docker exec -i infinicard_db psql -U infinicard_user -d infinicard < init-db\05-create-professionals.sql
```

## 📋 Step-by-Step Instructions

1. **Open Command Prompt**
   - Press `Win + R`
   - Type `cmd` and press Enter

2. **Navigate to Backend Folder**
   ```bash
   cd C:\Users\A\StudioProjects\infinicard\backend
   ```

3. **Run the Script**
   ```bash
   add-professionals-schema.bat
   ```

4. **Wait for Completion**
   - You should see "Migration completed successfully!"

5. **Test in Flutter App**
   - Hot restart your Flutter app (press `r` in terminal)
   - Navigate to Discover screen
   - You should see 8 professionals

## ✅ Verify It's Working

After running the script, you should see in your terminal:
```
GET /api/discover/locations 200
GET /api/discover/professionals? 200
GET /api/discover/fields 200
```

## 🔍 Troubleshooting

### "docker: command not found"
**Solution**: Make sure Docker Desktop is installed and running
- Check if Docker Desktop is running in your system tray
- Restart Docker Desktop if needed

### "cannot connect to Docker daemon"
**Solution**: Start Docker Desktop
- Open Docker Desktop application
- Wait until it shows "Docker Desktop is running"

### "port is already allocated"
**Solution**: Stop the existing container first
```bash
docker-compose down
docker-compose up -d
```

### "relation already exists"
**Solution**: Tables already exist! Your database is ready. Just restart Node.js:
```bash
npm start
```

### Still Getting 404?
**Check if Node.js server is running**:
```bash
cd backend
npm start
```

Look for:
```
Server running on port 3000
Database connected successfully
```

## 📊 Verify Tables in Database

You can check if tables were created using Adminer:

1. Open http://localhost:8080
2. Login:
   - System: `PostgreSQL`
   - Server: `postgres`
   - Username: `infinicard_user`
   - Password: `infinicard_pass_2024`
   - Database: `infinicard`

3. Click "Select" and look for:
   - `professionals` (should have 8 rows)
   - `professional_tags` (should have ~24 rows)
   - `connections` (empty initially)

## 🎯 Expected Results

After successful setup, in your Flutter Discover screen you should see:

### Professionals List:
- Sarah Williams (Full Stack Developer, Mumbai)
- Michael Chen (Product Designer, Bangalore)
- Priya Sharma (Marketing Manager, Delhi)
- David Kumar (Data Scientist, Pune)
- Emma Johnson (Business Analyst, Mumbai)
- Raj Patel (Frontend Developer, Bangalore)
- Lisa Anderson (Content Writer, Delhi)
- Arjun Singh (UX Researcher, Pune)

### Location Filter:
- All, Mumbai, Delhi, Bangalore, Pune

### Field Filter:
- All, Technology, Marketing, Design, Finance

### Connection Features:
- Click "Connect" button to send connection request
- Status changes to "Pending" after sending
- Other users can accept/reject requests

## 📝 What Was Added

The SQL migration creates:
- **professionals table**: Professional profiles
- **professional_tags table**: Skills/tags for professionals
- **connections table**: Connection requests between users
- **Indexes**: For fast queries
- **Triggers**: Auto-update connection counts
- **8 Demo Records**: Sample professionals with tags

## 🆘 Still Having Issues?

1. **Check Docker is Running**:
   ```bash
   docker ps
   ```
   You should see `infinicard_db` and `infinicard_adminer`

2. **Check Node.js is Running**:
   Look for the terminal where you ran `npm start`
   It should show "Server running on port 3000"

3. **Check Database Connection**:
   Visit http://localhost:3000/health
   Should return `{"success": true, "database": "connected"}`

4. **Check Logs**:
   ```bash
   # Docker logs
   docker logs infinicard_db
   
   # Node.js logs
   # Check the terminal where npm start is running
   ```

## 📚 Additional Resources

- `DISCOVER_BACKEND_INTEGRATION.md` - Full integration documentation
- `backend/API_DOCUMENTATION.md` - Complete API reference
- `backend/QUICK_START.txt` - Backend setup guide
- `QUICK_FIX_404.md` - Detailed troubleshooting

---

**Need help?** Check the error messages in:
1. Command Prompt (where you ran the script)
2. Node.js terminal (where npm start is running)
3. Flutter app console (for API errors)
