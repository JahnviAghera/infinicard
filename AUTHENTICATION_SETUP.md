# ✅ INFINICARD AUTHENTICATION - SETUP COMPLETE

## 🎉 What's Been Created

### ✅ Backend API Server (Node.js + Express)
- **Location:** `backend/`
- **Authentication endpoints:** Register, Login, Profile, Logout
- **JWT token generation** with bcrypt password hashing
- **PostgreSQL database integration**
- **CORS and security** middleware
- **Rate limiting** protection

### ✅ Database (PostgreSQL)
- **Running on Docker** (port 5433)
- **Tables created:** users, business_cards, contacts, tags, etc.
- **Adminer UI** available at http://localhost:8080

### ✅ Flutter App Authentication
- **API Service:** Complete REST client with token management
- **Login Screen:** Beautiful gradient UI with validation
- **Register Screen:** Full registration form with terms checkbox
- **Auth Flow:** Automatic token storage and session management
- **Logout:** Implemented in Settings screen

---

## 🚀 HOW TO START EVERYTHING

### Option 1: Automated (Recommended)

**Double-click this file:**
```
backend\start-server.bat
```

This will:
1. Check Node.js installation
2. Install dependencies automatically
3. Start the API server

### Option 2: Manual Commands

**Open Command Prompt (cmd.exe):**

```cmd
cd c:\Users\A\StudioProjects\infinicard\backend
npm install
npm start
```

---

## 📱 USING THE APP

### 1. Start the Backend Server

```cmd
cd c:\Users\A\StudioProjects\infinicard\backend
npm start
```

**Wait for this message:**
```
🚀 INFINICARD API SERVER STARTED
✅ Connected to PostgreSQL database
```

### 2. Run Flutter App

**In VS Code:** Press `F5`

**Or in terminal:**
```cmd
cd c:\Users\A\StudioProjects\infinicard
flutter run
```

### 3. Test Authentication

**Register New Account:**
1. App opens to Login Screen
2. Click "Create New Account"
3. Fill in:
   - Full Name: John Doe
   - Username: johndoe  
   - Email: john@example.com
   - Password: Password123
   - Confirm Password: Password123
4. Check "Terms and Conditions"
5. Click "Create Account"
6. ✅ You're logged in!

**Login:**
1. Enter email and password
2. Click "Login"
3. ✅ Redirected to Home

**Logout:**
1. Go to Settings
2. Scroll to "Account" section
3. Click "Logout"
4. Confirm
5. ✅ Back to Login screen

---

## 🔑 WHAT YOU NEED TO KNOW

### JWT Tokens
- **Generated on login/register**
- **Stored in SharedPreferences** (Flutter)
- **Valid for 7 days** (configurable)
- **Sent with every API request** in Authorization header

### Password Security
- **Hashed with bcrypt** (10 rounds)
- **Never stored in plain text**
- **Server-side validation**

### API Base URL
Currently set to: `http://localhost:3000/api`

**To change:**
Edit `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://your-server.com/api';
```

### JWT Secret
Located in `backend/.env`:
```
JWT_SECRET=infinicard-super-secret-jwt-key-change-in-production-2024
```

**⚠️ IMPORTANT:** Change this before deploying to production!

Generate a new secret:
```cmd
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

---

## 📊 ARCHITECTURE

```
┌──────────────────────┐
│   Flutter App        │  Your Device/Emulator
│   (Login/Register)   │  
└──────────┬───────────┘
           │
           │ HTTP POST /api/auth/login
           │ {email, password}
           │
           ▼
┌──────────────────────┐
│   Express API        │  http://localhost:3000
│   - Auth Controller  │
│   - JWT Middleware   │
│   - Password Hash    │
└──────────┬───────────┘
           │
           │ SQL Query
           │ SELECT * FROM users WHERE email=?
           │
           ▼
┌──────────────────────┐
│   PostgreSQL DB      │  localhost:5433
│   - users table      │  (Docker)
│   - password_hash    │
└──────────────────────┘
```

---

## 🛠️ FILES CREATED/MODIFIED

### Backend Files
```
backend/
├── package.json                    # Dependencies
├── .env                           # Configuration (JWT secret, DB creds)
├── start-server.bat               # Windows startup script
└── src/
    ├── server.js                  # Main Express server
    ├── config/
    │   └── database.js            # PostgreSQL connection
    ├── middleware/
    │   └── auth.js                # JWT verification
    ├── controllers/
    │   └── authController.js      # Login/Register logic
    └── routes/
        └── auth.js                # API routes
```

### Flutter Files
```
lib/
├── main.dart                      # Added auth check on startup
├── services/
│   └── api_service.dart          # NEW: API client with JWT
├── screens/
    ├── login_screen.dart         # NEW: Login UI
    ├── register_screen.dart      # NEW: Registration UI
    └── settings_screen.dart      # Modified: Added logout
```

### Documentation
```
├── STARTUP_GUIDE.md              # Complete setup guide
└── AUTHENTICATION_SETUP.md       # This file
```

---

## 🧪 TESTING THE API

### Using cURL

**Register:**
```cmd
curl -X POST http://localhost:3000/api/auth/register ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"test@test.com\",\"username\":\"testuser\",\"password\":\"Test123\",\"fullName\":\"Test User\"}"
```

**Login:**
```cmd
curl -X POST http://localhost:3000/api/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"test@test.com\",\"password\":\"Test123\"}"
```

**Get Profile (needs token):**
```cmd
curl -X GET http://localhost:3000/api/auth/profile ^
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Using Browser

Open: http://localhost:3000/health

Should see:
```json
{
  "success": true,
  "message": "Infinicard API is running"
}
```

---

## 🐛 COMMON ISSUES

### Error: "Connection refused" in Flutter app
**Solution:** Start the backend server first
```cmd
cd backend
npm start
```

### Error: "EADDRINUSE: address already in use"
**Solution:** Port 3000 is taken, kill the process:
```cmd
netstat -ano | findstr :3000
taskkill /PID <PID> /F
```

### Error: "Cannot find module 'express'"
**Solution:** Install dependencies:
```cmd
cd backend
npm install
```

### Error: PowerShell script execution disabled
**Solution:** Use `cmd.exe` instead of PowerShell
OR run: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

---

## 📦 NPM PACKAGES USED

| Package | Purpose |
|---------|---------|
| `express` | Web framework |
| `pg` | PostgreSQL client |
| `bcryptjs` | Password hashing |
| `jsonwebtoken` | JWT token generation |
| `cors` | Cross-origin requests |
| `dotenv` | Environment variables |
| `express-validator` | Input validation |
| `express-rate-limit` | Rate limiting |
| `helmet` | Security headers |
| `morgan` | HTTP logging |

---

## 🔒 SECURITY CHECKLIST

### Development (Current Setup)
- ✅ Passwords hashed with bcrypt
- ✅ JWT tokens with expiration
- ✅ CORS enabled for all origins
- ✅ Rate limiting (100 req/15min)
- ✅ SQL injection protection (parameterized queries)
- ✅ Helmet security headers

### Before Production
- ⚠️ Change JWT_SECRET to random 64-byte string
- ⚠️ Update database password
- ⚠️ Restrict CORS to your domain only
- ⚠️ Enable HTTPS
- ⚠️ Set NODE_ENV=production
- ⚠️ Add logging and monitoring
- ⚠️ Implement refresh token rotation
- ⚠️ Add email verification

---

## 📚 API DOCUMENTATION

Full API documentation available at:
- `backend/API_DOCUMENTATION.md`

**Endpoints:**
- `POST /api/auth/register` - Create account
- `POST /api/auth/login` - Login
- `GET /api/auth/profile` - Get profile (requires auth)
- `PUT /api/auth/profile` - Update profile (requires auth)
- `POST /api/auth/change-password` - Change password (requires auth)

---

## 🎯 NEXT STEPS

### You're ready to:
1. ✅ **Test the authentication** - Register and login
2. ✅ **View database** - Open http://localhost:8080
3. ✅ **Add more features** - Business cards API, contacts, etc.
4. ✅ **Customize UI** - Modify login/register screens
5. ✅ **Deploy** - See deployment guides

### Additional Features to Add:
- [ ] Forgot password / Reset password
- [ ] Email verification
- [ ] Social login (Google, Apple)
- [ ] Two-factor authentication
- [ ] Profile photo upload
- [ ] Remember me checkbox
- [ ] Biometric authentication

---

## 📞 SUPPORT

Having issues? Check:

1. **STARTUP_GUIDE.md** - Detailed step-by-step guide
2. **Backend logs** - Look at terminal running `npm start`
3. **Flutter logs** - Check VS Code debug console
4. **Database** - Open Adminer at http://localhost:8080

---

## 🎊 YOU'RE ALL SET!

Your Infinicard app now has:
✅ Complete authentication system  
✅ Secure JWT token management  
✅ Beautiful login/register screens  
✅ Password hashing and validation  
✅ Session persistence  
✅ PostgreSQL database backend  

**Start the server and enjoy your app!**

```cmd
cd backend
npm start
```

Then press `F5` in VS Code to run your Flutter app.

Happy coding! 🚀
