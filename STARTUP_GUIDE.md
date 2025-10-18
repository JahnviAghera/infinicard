# 🚀 INFINICARD STARTUP GUIDE

Complete step-by-step guide to start your Infinicard app with authentication.

## 📋 Prerequisites

- ✅ Docker Desktop running (for database)
- ✅ Node.js installed (v16+)
- ✅ Flutter installed
- ✅ Port 3000 free (for API server)
- ✅ Port 5433 free (for PostgreSQL)
- ✅ Port 8080 free (for Adminer)

---

## 🎯 STEP 1: Start the Database (Already Done ✅)

Your PostgreSQL database is running on Docker:

```bash
cd backend
docker-compose ps
```

Expected output:
```
NAME                 STATUS
infinicard_db        Up (healthy)
infinicard_adminer   Up
```

---

## 🎯 STEP 2: Install Backend Dependencies

Open **Command Prompt** (not PowerShell) and run:

```cmd
cd c:\Users\A\StudioProjects\infinicard\backend
npm install
```

This will install:
- `express` - Web framework
- `pg` - PostgreSQL client
- `bcryptjs` - Password hashing
- `jsonwebtoken` - JWT tokens
- `cors` - Cross-origin support
- `dotenv` - Environment variables
- And more...

**Expected output:**
```
added 120 packages in 15s
```

---

## 🎯 STEP 3: Start the API Server

Still in the backend directory, run:

```cmd
npm start
```

OR for development with auto-reload:

```cmd
npm run dev
```

**Expected output:**
```
╔════════════════════════════════════════════════════════════╗
║            🚀 INFINICARD API SERVER STARTED                ║
╠════════════════════════════════════════════════════════════╣
║  Status:   ✅ Running                                      ║
║  Port:     3000                                            ║
║  URL:      http://localhost:3000                          ║
║  API:      http://localhost:3000/api                      ║
║  Health:   http://localhost:3000/health                   ║
╚════════════════════════════════════════════════════════════╝

✅ Connected to PostgreSQL database

📋 Available endpoints:
   POST   /api/auth/register    - Register new user
   POST   /api/auth/login       - Login user
   GET    /api/auth/profile     - Get user profile
```

**Test the API:**

Open browser to: http://localhost:3000/health

You should see:
```json
{
  "success": true,
  "message": "Infinicard API is running",
  "timestamp": "2025-10-18T..."
}
```

---

## 🎯 STEP 4: Install Flutter Dependencies

Open a **NEW terminal** (keep the API server running), navigate to your project:

```cmd
cd c:\Users\A\StudioProjects\infinicard
flutter pub get
```

This will install the `http` package and other dependencies.

---

## 🎯 STEP 5: Run the Flutter App

```cmd
flutter run
```

OR if using VS Code:
- Press `F5` or click "Run" → "Start Debugging"

---

## 🎯 STEP 6: Test the Authentication Flow

### 1. **Register a New Account**

When the app opens, you'll see the **Login Screen**.

Click **"Create New Account"** button.

Fill in the registration form:
- **Full Name:** John Doe
- **Username:** johndoe
- **Email:** john@example.com
- **Password:** Password123
- **Confirm Password:** Password123
- ✅ Check "I agree to Terms and Conditions"

Click **"Create Account"**

**What happens:**
1. Flutter app sends POST request to `http://localhost:3000/api/auth/register`
2. Backend validates data
3. Backend creates user in PostgreSQL
4. Backend returns JWT access token
5. Flutter app saves token to SharedPreferences
6. You're redirected to the Home screen

### 2. **Login with Existing Account**

From the Login Screen, enter:
- **Email:** john@example.com
- **Password:** Password123

Click **"Login"**

**What happens:**
1. Flutter app sends POST to `http://localhost:3000/api/auth/login`
2. Backend verifies credentials
3. Backend returns JWT token
4. App saves token and redirects to Home

### 3. **Logout**

Once logged in:
1. Navigate to **Settings** screen (from bottom nav or drawer)
2. Scroll down to "Account" section
3. Click **"Logout"** button
4. Confirm logout
5. Redirected back to Login screen
6. Token cleared from storage

---

## 🔧 Troubleshooting

### Problem 1: "Network error: Connection refused"

**Cause:** API server is not running

**Solution:**
```cmd
cd c:\Users\A\StudioProjects\infinicard\backend
npm start
```

### Problem 2: "EADDRINUSE: address already in use :::3000"

**Cause:** Port 3000 is already taken

**Solution Option 1** - Kill the process:
```cmd
netstat -ano | findstr :3000
taskkill /PID <PID_NUMBER> /F
```

**Solution Option 2** - Change port:
Edit `backend\.env`:
```
API_PORT=3001
```

Then update `lib\services\api_service.dart`:
```dart
static const String baseUrl = 'http://localhost:3001/api';
```

### Problem 3: "Connection to PostgreSQL failed"

**Solution:**
```cmd
cd c:\Users\A\StudioProjects\infinicard\backend
docker-compose up -d
docker-compose ps
```

### Problem 4: "Cannot run Flutter app"

**Solution:**
```cmd
flutter doctor
flutter clean
flutter pub get
flutter run
```

### Problem 5: PowerShell script execution disabled

**Solution:** Use **cmd.exe** instead of PowerShell

OR enable scripts in PowerShell (run as Administrator):
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 📱 Testing the API with cURL or Postman

### Register User

```bash
curl -X POST http://localhost:3000/api/auth/register ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"test@example.com\",\"username\":\"testuser\",\"password\":\"Test123\",\"fullName\":\"Test User\"}"
```

### Login User

```bash
curl -X POST http://localhost:3000/api/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"test@example.com\",\"password\":\"Test123\"}"
```

Copy the `accessToken` from the response, then:

### Get Profile

```bash
curl -X GET http://localhost:3000/api/auth/profile ^
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN_HERE"
```

---

## 🔐 Important Security Notes

### ⚠️ Before Production:

1. **Change JWT Secret** in `backend\.env`:
```
JWT_SECRET=your-random-super-secure-secret-key-here
```

Generate a secure key:
```cmd
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

2. **Change Database Password** in `backend\.env` and `backend\docker-compose.yml`

3. **Enable HTTPS** for production

4. **Restrict CORS** in `backend\.env`:
```
CORS_ORIGIN=https://yourdomain.com
```

---

## 📊 Architecture Overview

```
┌─────────────────┐
│  Flutter App    │  (Your Phone/Emulator)
│  Port: Dynamic  │
└────────┬────────┘
         │
         │ HTTP Requests
         │ (with JWT token)
         ▼
┌─────────────────┐
│  Express API    │  http://localhost:3000
│  Node.js Server │
└────────┬────────┘
         │
         │ SQL Queries
         ▼
┌─────────────────┐
│  PostgreSQL DB  │  localhost:5433
│  Docker         │
└─────────────────┘
         │
         │ Web UI
         ▼
┌─────────────────┐
│  Adminer        │  http://localhost:8080
│  DB Admin Panel │
└─────────────────┘
```

---

## 📁 Key Files

### Backend (Node.js/Express)
- `backend/src/server.js` - Main API server
- `backend/src/config/database.js` - PostgreSQL connection
- `backend/src/controllers/authController.js` - Auth logic
- `backend/src/middleware/auth.js` - JWT verification
- `backend/src/routes/auth.js` - API routes
- `backend/.env` - Configuration (JWT secret, DB credentials)

### Frontend (Flutter)
- `lib/main.dart` - App entry point with auth check
- `lib/services/api_service.dart` - API client (login, register, etc.)
- `lib/screens/login_screen.dart` - Login UI
- `lib/screens/register_screen.dart` - Registration UI
- `lib/screens/settings_screen.dart` - Logout button

### Database
- `backend/init-db/01-create-schema.sql` - Database tables
- `backend/docker-compose.yml` - Docker configuration

---

## 🎉 Success Checklist

✅ Docker containers running (postgres, adminer)  
✅ Database accessible at http://localhost:8080  
✅ Backend API running on port 3000  
✅ API health check returns 200 OK  
✅ Flutter dependencies installed  
✅ Flutter app running on emulator/device  
✅ Can register new account  
✅ Can login with credentials  
✅ JWT token saved to SharedPreferences  
✅ Can access authenticated screens  
✅ Can logout successfully  

---

## 📞 Need Help?

### Check Logs

**Backend logs:**
```cmd
# Server is running in terminal - watch for errors
```

**Database logs:**
```cmd
docker-compose logs -f postgres
```

**Flutter logs:**
```cmd
# Running in terminal or VS Code debug console
```

### Verify Services

**Check all ports:**
```cmd
netstat -ano | findstr "3000 5433 8080"
```

---

## 🚀 Quick Start Commands (Copy-Paste)

**Terminal 1 - Database:**
```cmd
cd c:\Users\A\StudioProjects\infinicard\backend
docker-compose up -d
```

**Terminal 2 - API Server:**
```cmd
cd c:\Users\A\StudioProjects\infinicard\backend
npm install
npm start
```

**Terminal 3 - Flutter App:**
```cmd
cd c:\Users\A\StudioProjects\infinicard
flutter pub get
flutter run
```

---

**🎊 That's it! Your full-stack Infinicard app with authentication is ready!**
